import 'dart:async';
import 'package:flutter/services.dart';
import 'ai/ai_client.dart';
import 'ai/system_prompt.dart';

class BunbuAgentManager {
  BunbuAgentManager._();
  static final instance = BunbuAgentManager._();

  static const _channel = MethodChannel('bunbu/agent_manager');

  AiClient? _aiClient;
  final List<AiMessage> _history = [];
  bool _isStreaming = false;

  static Future<void> initialize({
    required String apiKey,
    AiModel model = AiModel.claude4Sonnet,
  }) async {
    final mgr = instance;
    mgr._aiClient = AiClient(
      config: AiConfig(apiKey: apiKey, model: model),
    );
    _channel.setMethodCallHandler(mgr._handleMethodCall);
    await _channel.invokeMethod('initialize');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'sendMessage':
        final text = call.arguments as String;
        _handleSendMessage(text);
        return null;
      case 'stopGeneration':
        _isStreaming = false;
        return null;
      case 'setModel':
        final modelId = call.arguments as String;
        _setModel(modelId);
        return null;
      case 'onDismiss':
        return null;
      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: '${call.method} not implemented',
        );
    }
  }

  void _setModel(String modelId) {
    if (_aiClient == null) return;
    final model = AiModel.values.firstWhere(
      (m) => m.id == modelId,
      orElse: () => AiModel.claude4Sonnet,
    );
    _aiClient!.config = _aiClient!.config.copyWith(model: model);
  }

  void _handleSendMessage(String text) async {
    if (_aiClient == null || _isStreaming) return;

    _history.add(AiMessage(role: AiRole.user, content: text));
    _isStreaming = true;

    try {
      const systemPrompt = BunbuSystemPrompt.base;
      final stream = _aiClient!.streamMessage(
        _history,
        systemPrompt: systemPrompt,
      );

      final buffer = StringBuffer();

      await for (final chunk in stream) {
        if (!_isStreaming) break;
        buffer.write(chunk);
        _channel.invokeMethod('onStreamChunk', chunk);
      }

      _history.add(AiMessage(role: AiRole.assistant, content: buffer.toString()));
      _channel.invokeMethod('onStreamDone', null);
    } catch (e) {
      _channel.invokeMethod('onStreamError', e.toString());
    } finally {
      _isStreaming = false;
    }
  }

  Future<void> show() async {
    await _channel.invokeMethod('show');
  }

  Future<void> hide() async {
    await _channel.invokeMethod('hide');
  }
}

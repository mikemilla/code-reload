import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

enum AiModel {
  claude4Sonnet('claude-sonnet-4-20250514', 'Claude 4 Sonnet', AiProvider.anthropic),
  claude4Opus('claude-opus-4-0-20250514', 'Claude 4 Opus', AiProvider.anthropic),
  gpt4o('gpt-4o', 'GPT-4o', AiProvider.openai),
  gpt4oMini('gpt-4o-mini', 'GPT-4o Mini', AiProvider.openai);

  const AiModel(this.id, this.displayName, this.provider);
  final String id;
  final String displayName;
  final AiProvider provider;
}

enum AiProvider { anthropic, openai }

enum AiRole { user, assistant, system }

class AiMessage {
  const AiMessage({required this.role, required this.content});
  final AiRole role;
  final String content;

  Map<String, dynamic> toJson() => {
        'role': role == AiRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

class AiConfig {
  const AiConfig({
    required this.apiKey,
    this.model = AiModel.claude4Sonnet,
    this.maxTokens = 4096,
  });
  final String apiKey;
  final AiModel model;
  final int maxTokens;

  AiConfig copyWith({String? apiKey, AiModel? model, int? maxTokens}) {
    return AiConfig(
      apiKey: apiKey ?? this.apiKey,
      model: model ?? this.model,
      maxTokens: maxTokens ?? this.maxTokens,
    );
  }
}

class AiClient {
  AiClient({required this.config, http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  AiConfig config;
  final http.Client _http;

  Future<String> sendMessage(
    List<AiMessage> messages, {
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async {
    switch (config.model.provider) {
      case AiProvider.anthropic:
        return _sendAnthropic(messages, systemPrompt: systemPrompt, tools: tools);
      case AiProvider.openai:
        return _sendOpenAi(messages, systemPrompt: systemPrompt, tools: tools);
    }
  }

  Stream<String> streamMessage(
    List<AiMessage> messages, {
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) {
    switch (config.model.provider) {
      case AiProvider.anthropic:
        return _streamAnthropic(messages, systemPrompt: systemPrompt);
      case AiProvider.openai:
        return _streamOpenAi(messages, systemPrompt: systemPrompt);
    }
  }

  Future<String> _sendAnthropic(
    List<AiMessage> messages, {
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async {
    final body = <String, dynamic>{
      'model': config.model.id,
      'max_tokens': config.maxTokens,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (systemPrompt != null) body['system'] = systemPrompt;
    if (tools != null) body['tools'] = tools;

    final response = await _http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': config.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw AiClientException(
        'Anthropic API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = json['content'] as List;
    final textBlocks = content.where((b) => b['type'] == 'text');
    return textBlocks.map((b) => b['text']).join('\n');
  }

  Future<String> _sendOpenAi(
    List<AiMessage> messages, {
    String? systemPrompt,
    List<Map<String, dynamic>>? tools,
  }) async {
    final allMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      allMessages.add({'role': 'system', 'content': systemPrompt});
    }
    allMessages.addAll(messages.map((m) => m.toJson()));

    final body = <String, dynamic>{
      'model': config.model.id,
      'max_tokens': config.maxTokens,
      'messages': allMessages,
    };
    if (tools != null) body['tools'] = tools;

    final response = await _http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.apiKey}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw AiClientException(
        'OpenAI API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List;
    return choices.first['message']['content'] as String;
  }

  Stream<String> _streamAnthropic(
    List<AiMessage> messages, {
    String? systemPrompt,
  }) async* {
    final body = <String, dynamic>{
      'model': config.model.id,
      'max_tokens': config.maxTokens,
      'stream': true,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (systemPrompt != null) body['system'] = systemPrompt;

    final request = http.Request(
      'POST',
      Uri.parse('https://api.anthropic.com/v1/messages'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    });
    request.body = jsonEncode(body);

    final streamed = await _http.send(request);
    if (streamed.statusCode != 200) {
      final errorBody = await streamed.stream.bytesToString();
      throw AiClientException(
        'Anthropic stream error ${streamed.statusCode}: $errorBody',
      );
    }

    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6);
      if (data == '[DONE]') break;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        if (json['type'] == 'content_block_delta') {
          final delta = json['delta'] as Map<String, dynamic>;
          if (delta['type'] == 'text_delta') {
            yield delta['text'] as String;
          }
        }
      } catch (_) {}
    }
  }

  Stream<String> _streamOpenAi(
    List<AiMessage> messages, {
    String? systemPrompt,
  }) async* {
    final allMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      allMessages.add({'role': 'system', 'content': systemPrompt});
    }
    allMessages.addAll(messages.map((m) => m.toJson()));

    final request = http.Request(
      'POST',
      Uri.parse('https://api.openai.com/v1/chat/completions'),
    );
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    });
    request.body = jsonEncode({
      'model': config.model.id,
      'max_tokens': config.maxTokens,
      'stream': true,
      'messages': allMessages,
    });

    final streamed = await _http.send(request);
    if (streamed.statusCode != 200) {
      final errorBody = await streamed.stream.bytesToString();
      throw AiClientException(
        'OpenAI stream error ${streamed.statusCode}: $errorBody',
      );
    }

    final lines = streamed.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6);
      if (data == '[DONE]') break;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final delta = json['choices'][0]['delta'] as Map<String, dynamic>;
        if (delta.containsKey('content') && delta['content'] != null) {
          yield delta['content'] as String;
        }
      } catch (_) {}
    }
  }

  void dispose() {
    _http.close();
  }
}

class AiClientException implements Exception {
  const AiClientException(this.message);
  final String message;

  @override
  String toString() => 'AiClientException: $message';
}

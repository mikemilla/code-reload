import 'package:flutter/material.dart';
import 'package:flutter_eval/flutter_eval.dart';
import 'agent_manager.dart';

class BunbuHost extends StatelessWidget {
  const BunbuHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: BunbuAgentManager.instance.currentCode,
      builder: (context, code, _) {
        if (code == null) return child;
        return CompilerWidget(
          packages: {
            'bunbu_dynamic': {
              'main.dart': code,
            },
          },
          library: 'package:bunbu_dynamic/main.dart',
          function: 'Main.',
          onError: (context, error, stackTrace) {
            return Scaffold(
              appBar: AppBar(title: const Text('Compile Error')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          BunbuAgentManager.instance.currentCode.value = null;
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Revert to default'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

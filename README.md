# bunbu

On-device AI coding assistant for Flutter. Chat with an AI, generate widgets, and see them render live — right on your device, no server needed.

## Features

- **Chat interface** — A floating button overlay that opens a Cursor-style chat panel
- **Live preview** — AI-generated Flutter widgets compile and render on-device in ~0.1s via `flutter_eval`
- **Model selection** — Switch between Claude and GPT models on the fly
- **Tool system** — Extensible function-calling tools (GitHub push, custom tools)
- **Fully on-device** — Direct API calls to AI providers, no intermediary server

## Quick start

```dart
import 'package:bunbu/bunbu.dart';

void main() {
  runApp(
    BunbuOverlay(
      aiConfig: AiConfig(
        apiKey: 'your-api-key',
        model: AiModel.claude4Sonnet,
      ),
      child: const MyApp(),
    ),
  );
}
```

## Limitations

The live preview uses `dart_eval` under the hood, which supports a subset of Dart:

- Basic Material widgets (Scaffold, AppBar, Container, Text, Column, Row, ListView, etc.)
- No mixins, extension methods, generators, or isolates
- No third-party package imports
- All generated code is self-contained in a single file

## License

MIT

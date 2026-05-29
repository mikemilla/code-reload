import 'dart:io';

class Shell {
  /// Runs a command and returns the result. Throws on non-zero exit code
  /// unless [throwOnError] is false.
  static Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool throwOnError = true,
    bool echoOutput = true,
  }) async {
    if (echoOutput) {
      stdout.writeln('\$ $executable ${arguments.join(' ')}');
    }

    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
    );

    if (echoOutput) {
      if ((result.stdout as String).isNotEmpty) {
        stdout.write(result.stdout);
      }
      if ((result.stderr as String).isNotEmpty) {
        stderr.write(result.stderr);
      }
    }

    if (throwOnError && result.exitCode != 0) {
      throw ProcessException(
        executable,
        arguments,
        'Command failed with exit code ${result.exitCode}',
        result.exitCode,
      );
    }

    return result;
  }

  /// Checks if a command is available on PATH.
  static Future<bool> hasCommand(String command) async {
    try {
      final result = await Process.run('which', [command], runInShell: true);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }
}

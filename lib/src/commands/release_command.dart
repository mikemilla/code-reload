import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../shell.dart';

class ReleaseCommand extends Command<void> {
  @override
  String get name => 'release';

  @override
  String get description =>
      'Create a Shorebird release build configured for a specific branch track.\n'
      'This builds the app with BRANCH_TRACK baked in and installs it on the '
      'connected device.';

  ReleaseCommand() {
    argParser
      ..addOption(
        'branch',
        abbr: 'b',
        help: 'The branch/track name this build will watch for updates.',
        mandatory: true,
      )
      ..addOption(
        'platform',
        abbr: 'p',
        help: 'Target platform.',
        allowed: ['android', 'ios'],
        defaultsTo: 'android',
      )
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'Path to the Flutter project (defaults to current directory).',
      )
      ..addOption(
        'flavor',
        help: 'Build flavor (if your project uses flavors).',
      )
      ..addOption(
        'target',
        abbr: 't',
        help: 'Main entry point (e.g., lib/main_dev.dart).',
      );
  }

  @override
  Future<void> run() async {
    final branch = argResults!['branch'] as String;
    final platform = argResults!['platform'] as String;
    final projectDir = argResults!['directory'] as String? ?? Directory.current.path;
    final flavor = argResults!['flavor'] as String?;
    final target = argResults!['target'] as String?;

    _validateProject(projectDir);

    stdout.writeln('Creating Shorebird release for branch track: $branch');
    stdout.writeln('Platform: $platform\n');

    final args = <String>[
      'release',
      platform,
      '--', '--dart-define=BRANCH_TRACK=$branch',
    ];

    if (flavor != null) {
      args.insertAll(2, ['--flavor', flavor]);
    }
    if (target != null) {
      args.insertAll(2, ['--target', target]);
    }

    await Shell.run('shorebird', args, workingDirectory: projectDir);

    stdout.writeln('\n✓ Release created for track: $branch');
    stdout.writeln('\nThe release APK/IPA has been registered with Shorebird.');
    stdout.writeln('Install it on your device, then future pushes to the "$branch" branch');
    stdout.writeln('will automatically update this app.\n');

    if (platform == 'android') {
      await _installAndroid(projectDir, branch);
    } else {
      stdout.writeln('For iOS, install the .ipa via Xcode or Apple Configurator.');
    }
  }

  void _validateProject(String dir) {
    final shorebirdYaml = File(p.join(dir, 'shorebird.yaml'));
    if (!shorebirdYaml.existsSync()) {
      throw StateError(
        'No shorebird.yaml found. Run "branch_push init" first.',
      );
    }
  }

  Future<void> _installAndroid(String dir, String branch) async {
    final apkDir = Directory(p.join(dir, 'build', 'app', 'outputs', 'flutter-apk'));
    if (!apkDir.existsSync()) {
      stdout.writeln('Could not find APK output directory. Install manually.');
      return;
    }

    final apkFile = apkDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('-release.apk'))
        .firstOrNull;

    if (apkFile == null) {
      stdout.writeln('No release APK found. You may need to install manually.');
      return;
    }

    stdout.writeln('Installing APK on connected device...');
    try {
      await Shell.run('adb', ['install', '-r', apkFile.path]);
      stdout.writeln('✓ App installed. It will watch the "$branch" track for updates.');
    } on ProcessException {
      stdout.writeln('adb install failed. Ensure a device is connected and try:');
      stdout.writeln('  adb install -r ${apkFile.path}');
    }
  }
}

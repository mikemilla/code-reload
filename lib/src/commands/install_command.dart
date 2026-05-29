import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../shell.dart';

class InstallCommand extends Command<void> {
  @override
  String get name => 'install';

  @override
  String get description =>
      'Install the app on a connected device configured to watch a specific branch track.\n'
      'Uses shorebird preview to download and run the release.';

  InstallCommand() {
    argParser
      ..addOption(
        'branch',
        abbr: 'b',
        help: 'The branch/track name this device should watch.',
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
        'release-version',
        help: 'Specific release version to install (reads from pubspec.yaml if omitted).',
      )
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'Path to the Flutter project (defaults to current directory).',
      );
  }

  @override
  Future<void> run() async {
    final branch = argResults!['branch'] as String;
    final platform = argResults!['platform'] as String;
    final projectDir = argResults!['directory'] as String? ?? Directory.current.path;
    final releaseVersion = argResults!['release-version'] as String? ?? _readVersion(projectDir);

    _validateProject(projectDir);

    stdout.writeln('Installing app for branch track: $branch');
    stdout.writeln('Platform: $platform');
    stdout.writeln('Release version: $releaseVersion\n');

    final appId = _readAppId(projectDir);

    final args = <String>[
      'preview',
      '--app-id', appId,
      '--release-version', releaseVersion,
      '--track', branch,
    ];

    stdout.writeln('Running shorebird preview to install on device...');
    await Shell.run('shorebird', args, workingDirectory: projectDir);

    stdout.writeln('\n✓ App installed and configured to watch "$branch" track.');
    stdout.writeln('Push commits to the "$branch" branch and the app will update automatically.');
  }

  void _validateProject(String dir) {
    final shorebirdYaml = File(p.join(dir, 'shorebird.yaml'));
    if (!shorebirdYaml.existsSync()) {
      throw StateError(
        'No shorebird.yaml found. Run "branch_push init" first.',
      );
    }
  }

  String _readVersion(String dir) {
    final pubspecFile = File(p.join(dir, 'pubspec.yaml'));
    if (!pubspecFile.existsSync()) {
      throw StateError('No pubspec.yaml found in $dir');
    }

    final yaml = loadYaml(pubspecFile.readAsStringSync()) as YamlMap;
    final version = yaml['version'] as String?;
    if (version == null) {
      throw StateError('No version field in pubspec.yaml');
    }
    return version;
  }

  String _readAppId(String dir) {
    final shorebirdFile = File(p.join(dir, 'shorebird.yaml'));
    final yaml = loadYaml(shorebirdFile.readAsStringSync()) as YamlMap;
    final appId = yaml['app_id'] as String?;
    if (appId == null) {
      throw StateError('No app_id in shorebird.yaml');
    }
    return appId;
  }
}

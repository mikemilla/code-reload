import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

import '../shell.dart';
import '../templates/github_action_template.dart';
import '../templates/updater_template.dart';

class InitCommand extends Command<void> {
  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize branch_push in a Flutter project.\n'
      'Sets up Shorebird, adds dependencies, generates the GitHub Action '
      'workflow, and creates the BranchPushUpdater helper.';

  InitCommand() {
    argParser.addOption(
      'directory',
      abbr: 'd',
      help: 'Path to the Flutter project (defaults to current directory).',
    );
  }

  @override
  Future<void> run() async {
    final projectDir = argResults!['directory'] as String? ?? Directory.current.path;

    stdout.writeln('Initializing branch_push in $projectDir...\n');

    _validateFlutterProject(projectDir);
    await _ensureShorebird();
    await _initShorebird(projectDir);
    _configureShorebirdYaml(projectDir);
    _addDependency(projectDir);
    _generateUpdaterFile(projectDir);
    _generateGitHubAction(projectDir);

    stdout.writeln('\n✓ branch_push initialized successfully!\n');
    stdout.writeln('Next steps:');
    stdout.writeln('  1. Run: flutter pub get');
    stdout.writeln('  2. Add BranchPushUpdater to your app (see lib/src/branch_push_updater.dart)');
    stdout.writeln('  3. Add SHOREBIRD_TOKEN to your GitHub repository secrets');
    stdout.writeln('  4. Create a release: branch_push release --branch <name> --platform android');
  }

  void _validateFlutterProject(String dir) {
    final pubspec = File(p.join(dir, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw StateError('No pubspec.yaml found in $dir. Is this a Flutter project?');
    }

    final content = loadYaml(pubspec.readAsStringSync()) as YamlMap;
    final deps = content['dependencies'] as YamlMap?;
    if (deps == null || !deps.containsKey('flutter')) {
      throw StateError('This does not appear to be a Flutter project (no flutter dependency).');
    }
  }

  Future<void> _ensureShorebird() async {
    final hasShorebird = await Shell.hasCommand('shorebird');
    if (!hasShorebird) {
      throw StateError(
        'Shorebird CLI not found. Install it first:\n'
        '  curl --proto "=https" --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash',
      );
    }
    stdout.writeln('✓ Shorebird CLI found');
  }

  Future<void> _initShorebird(String dir) async {
    final shorebirdYaml = File(p.join(dir, 'shorebird.yaml'));
    if (shorebirdYaml.existsSync()) {
      stdout.writeln('✓ Shorebird already initialized (shorebird.yaml exists)');
      return;
    }

    stdout.writeln('Running shorebird init...');
    await Shell.run('shorebird', ['init', '--force'], workingDirectory: dir);
    stdout.writeln('✓ Shorebird initialized');
  }

  void _configureShorebirdYaml(String dir) {
    final file = File(p.join(dir, 'shorebird.yaml'));
    if (!file.existsSync()) return;

    final content = file.readAsStringSync();
    final editor = YamlEditor(content);

    final yaml = loadYaml(content) as YamlMap;
    if (yaml['auto_update'] == false) {
      stdout.writeln('✓ auto_update already disabled');
      return;
    }

    editor.update(['auto_update'], false);
    file.writeAsStringSync(editor.toString());
    stdout.writeln('✓ Set auto_update: false in shorebird.yaml (updates managed by BranchPushUpdater)');
  }

  void _addDependency(String dir) {
    final file = File(p.join(dir, 'pubspec.yaml'));
    final content = file.readAsStringSync();

    if (content.contains('shorebird_code_push')) {
      stdout.writeln('✓ shorebird_code_push already in pubspec.yaml');
      return;
    }

    final editor = YamlEditor(content);
    editor.update(['dependencies', 'shorebird_code_push'], '^2.0.0');
    file.writeAsStringSync(editor.toString());
    stdout.writeln('✓ Added shorebird_code_push to pubspec.yaml');
  }

  void _generateUpdaterFile(String dir) {
    final outputDir = Directory(p.join(dir, 'lib', 'src'));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final file = File(p.join(outputDir.path, 'branch_push_updater.dart'));
    if (file.existsSync()) {
      stdout.writeln('✓ branch_push_updater.dart already exists');
      return;
    }

    file.writeAsStringSync(updaterTemplate);
    stdout.writeln('✓ Generated lib/src/branch_push_updater.dart');
  }

  void _generateGitHubAction(String dir) {
    final workflowDir = Directory(p.join(dir, '.github', 'workflows'));
    if (!workflowDir.existsSync()) {
      workflowDir.createSync(recursive: true);
    }

    final file = File(p.join(workflowDir.path, 'branch_push.yml'));
    if (file.existsSync()) {
      stdout.writeln('✓ .github/workflows/branch_push.yml already exists');
      return;
    }

    file.writeAsStringSync(githubActionTemplate);
    stdout.writeln('✓ Generated .github/workflows/branch_push.yml');
  }
}

import 'package:args/command_runner.dart';

import 'commands/init_command.dart';
import 'commands/release_command.dart';
import 'commands/install_command.dart';

class BranchPushRunner extends CommandRunner<void> {
  BranchPushRunner()
      : super(
          'branch_push',
          'Branch-based code push for Flutter apps.\n'
              'Maps git branches to Shorebird tracks for instant OTA updates.',
        ) {
    addCommand(InitCommand());
    addCommand(ReleaseCommand());
    addCommand(InstallCommand());
  }
}

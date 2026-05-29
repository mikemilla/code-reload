import 'dart:io';

import 'package:branch_push/branch_push.dart';

Future<void> main(List<String> args) async {
  final runner = BranchPushRunner();
  try {
    await runner.run(args);
  } on FormatException catch (e) {
    stderr.writeln('${e.message}\n');
    exit(64);
  } catch (e) {
    stderr.writeln('Error: $e');
    exit(1);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:bunbu/bunbu.dart';

void main() {
  group('BunbuAgentManager', () {
    test('instance is a singleton', () {
      final a = BunbuAgentManager.instance;
      final b = BunbuAgentManager.instance;
      expect(identical(a, b), isTrue);
    });
  });
}

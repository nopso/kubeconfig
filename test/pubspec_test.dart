import 'dart:io';

import 'package:kubeconfig/kubeconfig.dart';
import 'package:kubeconfig_cli/src/pubspec.dart';
import 'package:test/test.dart';

void main() {
  group('Pubspec', () {
    test('fields are not null', () {
      expect(Pubspec.versionFull, isNotNull);
      expect(Pubspec.repository, isNotNull);
      expect(Pubspec.buildDate, isNotNull);
    });

    test('versionFull is valid', () {
      final pubspecYaml =
          File('${gitRepoRoot()}/pubspec.yaml').readAsStringSync();
      final pubspec = pubspecYaml.yamlToJson();
      expect(Pubspec.versionFull, pubspec['version']);
    });
  });
}

String gitRepoRoot() =>
    (Process.runSync('git', ['rev-parse', '--show-toplevel']).stdout as String)
        .trim();

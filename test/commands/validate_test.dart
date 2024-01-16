import 'dart:io' hide stdin;

import 'package:args/args.dart';
import 'package:kubeconfig_cli/src/commands/command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('Command "kubeconfig validate"', () {
    late ArgResults argResults;
    late Logger logger;
    late Stdin stdin;
    late ValidateCommand command;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      stdin = _MockStdin();
      command = ValidateCommand(logger: logger, stdin: stdin)
        ..testArgResults = argResults
        ..testUsage = 'test usage';

      // default options
      when<dynamic>(() => argResults['json']).thenReturn('false');
    });

    test('returns software exit code when file option is not passed', () async {
      when(() => argResults.rest).thenReturn([]);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file path is not valid', () async {
      when<dynamic>(() => argResults['file']).thenReturn('missing-path');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file content is empty', () async {
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/empty.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file (yaml) content is not valid',
        () async {
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/invalid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file (json) content is not valid',
        () async {
      when<dynamic>(() => argResults['json']).thenReturn('true');
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/invalid.json');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when stdin is empty', () async {
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when(() => stdin.readLineSync()).thenAnswer((_) => null);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when stdin (yaml) is not valid', () async {
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when(() => stdin.readLineSync()).thenAnswer((_) => '`invalid`');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when stdin (json) is not valid', () async {
      when<dynamic>(() => argResults['json']).thenReturn('true');
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when(() => stdin.readLineSync()).thenAnswer((_) => '`invalid`');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test(
        'returns software exit code when file (yaml) is not a valid kubeconfig',
        () async {
      when<dynamic>(() => argResults['file']).thenReturn(
        'test/files/invalid_contexts_required.yaml',
      );
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when an unexpected error occurred',
        () async {
      var isFirstInvocation = true;
      when(() => logger.success(any())).thenAnswer((_) {
        if (isFirstInvocation) {
          isFirstInvocation = false;
          throw Exception();
        }
      });
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/valid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns success exit code when file (yaml) option is valid',
        () async {
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/valid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    test('returns success exit code when file (json) option is valid',
        () async {
      when<dynamic>(() => argResults['json']).thenReturn('true');
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/valid.json');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    test('returns success exit code when stdin (yaml) is valid', () async {
      final content = await File('test/files/valid.yaml').readAsString();
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when(() => stdin.readLineSync()).thenAnswer((_) => content);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    test('returns success exit code when stdin (json) is valid', () async {
      final content = await File('test/files/valid.json').readAsString();
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when<dynamic>(() => argResults['json']).thenReturn('true');
      when(() => stdin.readLineSync()).thenAnswer((_) => content);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });
  });
}

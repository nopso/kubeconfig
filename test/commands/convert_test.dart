import 'dart:io' hide stdin;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:kubeconfig_cli/src/commands/command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('Command "kubeconfig convert"', () {
    late ArgResults argResults;
    late Logger logger;
    late Stdin stdin;
    late FileSystem fs;
    late FileSystem fsMemory;
    late ConvertCommand command;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      stdin = _MockStdin();
      fs = const LocalFileSystem();
      fsMemory = MemoryFileSystem();
      command = ConvertCommand(logger: logger, stdin: stdin, fs: fs)
        ..testArgResults = argResults
        ..testUsage = 'test usage';

      // default options
      when<dynamic>(() => argResults['json']).thenReturn('false');
      when<dynamic>(() => argResults['indent']).thenReturn('2');
      when<dynamic>(() => argResults['validate']).thenReturn('true');
    });

    test('returns software exit code when "getContent" result is not valid',
        () async {
      when<dynamic>(() => argResults['file']).thenReturn('missing-path');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when "validate" result is not valid',
        () async {
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/invalid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when an unexpected convert error occurred',
        () async {
      when<dynamic>(() => argResults.name)
          .thenReturn('throw-convert-exception');
      when<dynamic>(() => argResults['file'])
          .thenReturn('test/files/valid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns success exit code when stdin (yaml) is valid', () async {
      final content = await fs.file('test/files/valid.yaml').readAsString();
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when(() => stdin.readLineSync()).thenAnswer((_) => content);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    test('returns success exit code when stdin (json) is valid', () async {
      final content = await fs.file('test/files/valid.json').readAsString();
      when<dynamic>(() => argResults['file']).thenReturn('-');
      when<dynamic>(() => argResults['json']).thenReturn('true');
      when(() => stdin.readLineSync()).thenAnswer((_) => content);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    group('in-memory-file', () {
      setUp(() async {
        command = ConvertCommand(logger: logger, stdin: stdin, fs: fsMemory)
          ..testArgResults = argResults
          ..testUsage = 'test usage';

        // in-memory yaml file
        final validYamlContent =
            await fs.file('test/files/valid.yaml').readAsString();
        final validYaml = fsMemory.systemTempDirectory.childFile('valid.yaml');
        await validYaml.writeAsString(validYamlContent);

        // in-memory json file
        final validJsonContent =
            await fs.file('test/files/valid.json').readAsString();
        final validJson = fsMemory.systemTempDirectory.childFile('valid.json');
        await validJson.writeAsString(validJsonContent);
      });

      test(
          'returns software exit code when an unexpected file write '
          'error occurred', () async {
        when<dynamic>(() => argResults.name).thenReturn('throw-file-exception');
        when<dynamic>(() => argResults['file'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/valid.yaml');
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/converted.json');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.software.code));
      });

      test('returns success exit code when file (yaml) option is valid',
          () async {
        when<dynamic>(() => argResults['file'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/valid.yaml');
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/converted.json');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.success.code));
      });

      test('returns success exit code when file (json) option is valid',
          () async {
        when<dynamic>(() => argResults['json']).thenReturn('true');
        when<dynamic>(() => argResults['file'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/valid.json');
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/converted.yaml');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.success.code));
      });
    });
  });
}

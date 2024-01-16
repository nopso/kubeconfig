import 'dart:io' hide stdin;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:kubeconfig_cli/src/commands/command.dart';
import 'package:kubeconfig_cli/src/commands/command_helper.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockArgResults extends Mock implements ArgResults {}

class _MockLogger extends Mock implements Logger {}

class _MockStdin extends Mock implements Stdin {}

void main() {
  group('Command "kubeconfig merge"', () {
    late ArgResults argResults;
    late Logger logger;
    late Stdin stdin;
    late FileSystem fs;
    late FileSystem fsMemory;
    late MergeCommand command;

    setUp(() {
      argResults = _MockArgResults();
      logger = _MockLogger();
      stdin = _MockStdin();
      fs = const LocalFileSystem();
      fsMemory = MemoryFileSystem();
      command = MergeCommand(logger: logger, stdin: stdin, fs: fs)
        ..testArgResults = argResults
        ..testUsage = 'test usage';

      // default options
      when<dynamic>(() => argResults['json']).thenReturn('false');
      when<dynamic>(() => argResults['indent']).thenReturn('2');
      when<dynamic>(() => argResults['validate']).thenReturn('true');
    });

    test('returns software exit code when files option is not passed',
        () async {
      when(() => argResults.rest).thenReturn([]);
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test(
        'returns software exit code when files does not contain path delimiter',
        () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('file1.yaml|file2.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when files less than 2', () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('file1.yaml$pathDelimiter');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when files greater than 9', () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('file1.yaml$pathDelimiter'
              'file2.yaml$pathDelimiter'
              'file3.yaml$pathDelimiter'
              'file4.yaml$pathDelimiter'
              'file5.yaml$pathDelimiter'
              'file6.yaml$pathDelimiter'
              'file7.yaml$pathDelimiter'
              'file8.yaml$pathDelimiter'
              'file9.yaml$pathDelimiter'
              'file10.yaml$pathDelimiter'
              'file11.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file path is not valid', () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('missing-path1$pathDelimiter'
              'missing-path2');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when file content is empty', () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('test/files/empty.yaml$pathDelimiter'
              'test/files/valid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when "getKubeconfig" result is not valid',
        () async {
      when<dynamic>(() => argResults['files'])
          .thenReturn('test/files/invalid.yaml$pathDelimiter'
              'test/files/valid.yaml');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when "validate" result is not valid',
        () async {
      when<dynamic>(() => argResults['files']).thenReturn(
        'test/files/invalid_cluster_certificate_both.yaml$pathDelimiter'
        'test/files/valid.yaml',
      );
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns software exit code when an unexpected merge error occurred',
        () async {
      when<dynamic>(() => argResults.name).thenReturn('throw-merge-exception');
      when<dynamic>(() => argResults['files']).thenReturn(
        'test/files/valid.yaml$pathDelimiter'
        'test/files/valid.yaml',
      );
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.software.code));
    });

    test('returns success exit code when yaml is valid', () async {
      when<dynamic>(() => argResults['files']).thenReturn(
        'test/files/valid.yaml$pathDelimiter'
        'test/files/valid_multi.yaml',
      );
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    test('returns success exit code when json is valid', () async {
      when<dynamic>(() => argResults['files']).thenReturn(
        'test/files/valid.json$pathDelimiter'
        'test/files/valid_multi.json',
      );
      when<dynamic>(() => argResults['json']).thenReturn('true');
      final exitCode = await command.run();
      expect(exitCode, equals(ExitCode.success.code));
    });

    group('in-memory-file', () {
      setUp(() async {
        command = MergeCommand(logger: logger, stdin: stdin, fs: fsMemory)
          ..testArgResults = argResults
          ..testUsage = 'test usage';

        // in-memory yaml files
        final validYamlContent =
            await fs.file('test/files/valid.yaml').readAsString();
        final validYaml = fsMemory.systemTempDirectory.childFile('valid.yaml');
        await validYaml.writeAsString(validYamlContent);

        final validMultiYamlContent =
            await fs.file('test/files/valid_multi.yaml').readAsString();
        final validMultiYaml =
            fsMemory.systemTempDirectory.childFile('valid_multi.yaml');
        await validMultiYaml.writeAsString(validMultiYamlContent);

        // in-memory json files
        final validJsonContent =
            await fs.file('test/files/valid.json').readAsString();
        final validJson = fsMemory.systemTempDirectory.childFile('valid.json');
        await validJson.writeAsString(validJsonContent);

        final validMultiJsonContent =
            await fs.file('test/files/valid_multi.json').readAsString();
        final validMultiJson =
            fsMemory.systemTempDirectory.childFile('valid_multi.json');
        await validMultiJson.writeAsString(validMultiJsonContent);
      });

      test(
          'returns software exit code when an unexpected file write '
          'error occurred', () async {
        when<dynamic>(() => argResults.name).thenReturn('throw-file-exception');
        when<dynamic>(() => argResults['files']).thenReturn(
          '${fsMemory.systemTempDirectory.path}/valid.yaml$pathDelimiter'
          '${fsMemory.systemTempDirectory.path}/valid_multi.yaml',
        );
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/merged.yaml');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.software.code));
      });

      test('returns success exit code when file (yaml) option is valid',
          () async {
        when<dynamic>(() => argResults['files']).thenReturn(
          '${fsMemory.systemTempDirectory.path}/valid.yaml$pathDelimiter'
          '${fsMemory.systemTempDirectory.path}/valid_multi.yaml',
        );
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/merged.yaml');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.success.code));
      });

      test('returns success exit code when file (json) option is valid',
          () async {
        when<dynamic>(() => argResults['json']).thenReturn('true');
        when<dynamic>(() => argResults['files']).thenReturn(
          '${fsMemory.systemTempDirectory.path}/valid.json$pathDelimiter'
          '${fsMemory.systemTempDirectory.path}/valid_multi.json',
        );
        when<dynamic>(() => argResults['output'])
            .thenReturn('${fsMemory.systemTempDirectory.path}/merged.json');
        final exitCode = await command.run();
        expect(exitCode, equals(ExitCode.success.code));
      });
    });
  });
}

import 'dart:async';
import 'dart:io';

import 'package:kubeconfig/kubeconfig.dart';
import 'package:kubeconfig_cli/src/command_runner.dart';
import 'package:kubeconfig_cli/src/pubspec.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockPubUpdater extends Mock implements PubUpdater {}

class _MockProcessSignal extends Mock implements ProcessSignal {}

class MockProgress extends Mock implements Progress {}

List<String> printLogs = <String>[];

const expectedUsage = [
  // ignore: no_adjacent_strings_in_list
  'A kubeconfig utility.\n'
      '\n'
      'Usage: kubeconfig <command> [arguments]\n'
      '\n'
      'Global options:\n'
      '-h, --help               Print this usage information.\n'
      '-v, --version            Print the current version.\n'
      '    --verbose            Output additional logs.\n'
      '    --update-from-pub    Update kubeconfig CLI from pub.dev\n'
      '                         (if installed with "dart pub global activate '
      'kubeconfig" command).\n'
      '\n'
      'Available commands:\n'
      '  convert    Convert a kubeconfig file.\n'
      '  merge      Merge kubeconfig files.\n'
      '  validate   Validate a kubeconfig file.\n'
      '\n'
      'Run "kubeconfig help <command>" for more information about a command.'
];
const latestVersion = '0.0.0';

void main() {
  group('CommandRunner', () {
    const processId = 42;
    final processResult = ProcessResult(processId, 0, '', '');
    late Logger logger;
    late ProcessSignal sigint;
    late PubUpdater pubUpdater;
    late KubeconfigCommandRunner commandRunner;

    setUp(() {
      logger = _MockLogger();
      sigint = _MockProcessSignal();
      pubUpdater = _MockPubUpdater();
      printLogs = [];

      when(() => logger.progress(any())).thenReturn(MockProgress());
      when(() => pubUpdater.getLatestVersion(any()))
          .thenAnswer((_) async => Pubspec.versionFull);
      when(
        () => pubUpdater.update(
          packageName: 'kubeconfig',
          versionConstraint: any(named: 'versionConstraint'),
        ),
      ).thenAnswer((_) => Future.value(processResult));
      when(() => sigint.watch()).thenAnswer((_) => const Stream.empty());

      commandRunner = KubeconfigCommandRunner(
        logger: logger,
        sigint: sigint,
        exit: (_) {},
        pubUpdater: pubUpdater,
      );
    });

    test('can be instantiated without any explicit parameters', () {
      final commandRunner = KubeconfigCommandRunner();
      expect(commandRunner, isNotNull);
    });

    group('run', () {
      test('shows usage when invalid option is passed', () async {
        final exitCode = await commandRunner.run(['--invalid-option']);
        expect(exitCode, ExitCode.usage.code);
        verify(
          () => logger.err(
            any(
              that: predicate<String>((message) {
                return message.contains(
                  'Could not find an option named "invalid-option".',
                );
              }),
            ),
          ),
        ).called(1);
        verify(
          () => logger.info(
            any(
              that: predicate<String>((message) {
                return message
                    .contains('Usage: kubeconfig <command> [arguments]');
              }),
            ),
          ),
        ).called(1);
      });

      test('shows usage when invalid command is passed', () async {
        final exitCode = await commandRunner.run(['invalid-command']);
        expect(exitCode, ExitCode.usage.code);
        verify(
          () => logger.err(
            any(
              that: predicate<String>((message) {
                return message.contains(
                  'Could not find a command named "invalid-command".',
                );
              }),
            ),
          ),
        ).called(1);
        verify(
          () => logger.info(
            any(
              that: predicate<String>((message) {
                return message
                    .contains('Usage: kubeconfig <command> [arguments]');
              }),
            ),
          ),
        ).called(1);
      });

      test('checks for updates on sigint', () async {
        final exitCalls = <int>[];
        commandRunner = KubeconfigCommandRunner(
          logger: logger,
          pubUpdater: pubUpdater,
          exit: exitCalls.add,
          sigint: sigint,
        );
        when(() => sigint.watch()).thenAnswer((_) => Stream.value(sigint));
        await commandRunner.run(['--version']);
        expect(exitCalls, equals([0]));
        verify(() => pubUpdater.getLatestVersion(any())).called(2);
      });

      test('prompts for update when newer version exists', () async {
        when(() => pubUpdater.getLatestVersion(any()))
            .thenAnswer((_) async => latestVersion);
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verify(
          () => logger.info(
            updateMessage.format([
              latestVersion,
              changelog!.format([latestVersion]),
            ]),
          ),
        ).called(1);
      });

      test('handles pub update errors gracefully', () async {
        when(() => pubUpdater.getLatestVersion(any()))
            .thenThrow(Exception('oops'));
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updateMessage));
      });

      test('handles exception', () async {
        final exception = Exception('oops!');
        var isFirstInvocation = true;
        when(() => logger.info(any())).thenAnswer((_) {
          if (isFirstInvocation) {
            isFirstInvocation = false;
            throw exception;
          }
        });
        final result = await commandRunner.run(['--version']);
        expect(result, equals(ExitCode.software.code));
        verify(() => logger.err('$exception')).called(1);
      });

      test(
        'handles no command',
        overridePrint(() async {
          final result = await commandRunner.run([]);
          expect(printLogs, equals(expectedUsage));
          expect(result, equals(ExitCode.success.code));
        }),
      );

      test(
          'does not show update message when the shell calls the '
          'completion command', () async {
        when(() => pubUpdater.getLatestVersion(any()))
            .thenAnswer((_) async => latestVersion);
        final result = await commandRunner.run(['completion']);
        expect(result, equals(ExitCode.success.code));
        verifyNever(() => logger.info(updateMessage));
      });

      group('--help', () {
        test(
          'outputs usage',
          overridePrint(() async {
            final result = await commandRunner.run(['--help']);
            expect(printLogs, equals(expectedUsage));
            expect(result, equals(ExitCode.success.code));

            printLogs.clear();

            final resultAbbr = await commandRunner.run(['-h']);
            expect(printLogs, equals(expectedUsage));
            expect(resultAbbr, equals(ExitCode.success.code));
          }),
        );
      });

      group('--verbose', () {
        test(
          'sets correct log level.',
          overridePrint(() async {
            await commandRunner.run(['--verbose']);
            verify(() => logger.level = Level.verbose).called(1);
          }),
        );

        test(
          'outputs correct meta info',
          overridePrint(() async {
            await commandRunner.run(['--verbose']);
            verify(
              () => logger.detail(
                '[meta] ${Pubspec.name} ${Pubspec.versionFull}',
              ),
            ).called(1);
          }),
        );
      });

      group('--version', () {
        test('outputs current version', () async {
          final result = await commandRunner.run(['--version']);
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.info(Pubspec.versionFull)).called(1);
        });
      });

      group('--update-from-pub', () {
        test('handles pub latest version query errors', () async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenThrow(Exception('oops'));
          final result = await commandRunner.run(['--update-from-pub']);
          expect(result, equals(ExitCode.software.code));
          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.err('Exception: oops'));
          verifyNever(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          );
        });

        test('handles pub update errors', () async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          ).thenThrow(Exception('oops'));
          final result = await commandRunner.run(['--update-from-pub']);
          expect(result, equals(ExitCode.software.code));
          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.err('Exception: oops'));
          verify(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          ).called(1);
        });

        test('handles pub update process errors', () async {
          const error = 'Oh no! Installing this is not possible right now!';
          final processResult = ProcessResult(processId, 1, '', error);
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          ).thenAnswer((_) => Future.value(processResult));
          final result = await commandRunner.run(['--update-from-pub']);
          expect(result, equals(ExitCode.software.code));
          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.err('Error updating kubeconfig CLI: $error'));
          verify(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          ).called(1);
        });

        test('updates when newer version exists', () async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => latestVersion);
          when(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          ).thenAnswer((_) => Future.value(processResult));

          when(() => logger.progress(any())).thenReturn(MockProgress());
          final result = await commandRunner.run(['--update-from-pub']);
          expect(result, equals(ExitCode.success.code));
          verify(() => logger.progress('Checking for updates')).called(1);
          verify(() => logger.progress('Updating to $latestVersion')).called(1);
          verify(
            () => pubUpdater.update(
              packageName: 'kubeconfig',
              versionConstraint: latestVersion,
            ),
          ).called(1);
        });

        test('does not update when already on latest version', () async {
          when(
            () => pubUpdater.getLatestVersion(any()),
          ).thenAnswer((_) async => Pubspec.versionFull);
          when(() => logger.progress(any())).thenReturn(MockProgress());
          final result = await commandRunner.run(['--update-from-pub']);
          expect(result, equals(ExitCode.success.code));
          verify(
            () => logger.info('kubeconfig is already at the latest version.'),
          ).called(1);
          verifyNever(() => logger.progress('Updating to $latestVersion'));
          verifyNever(
            () => pubUpdater.update(
              packageName: any(named: 'packageName'),
              versionConstraint: any(named: 'versionConstraint'),
            ),
          );
        });
      });
    });
  });
}

void Function() overridePrint(void Function() fn) {
  return () {
    final spec = ZoneSpecification(
      print: (self, parent, zone, message) {
        printLogs.add(message);
      },
    );
    return Zone.current.fork(specification: spec).run<void>(fn);
  };
}

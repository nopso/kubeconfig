import 'dart:io' as io;
import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:kubeconfig/kubeconfig.dart';
import 'package:kubeconfig_cli/src/commands/command.dart';
import 'package:kubeconfig_cli/src/extensions/arg_parser_extensions.dart';
import 'package:kubeconfig_cli/src/pubspec.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:pub_updater/pub_updater.dart';

/// Typedef for [io.exit].
typedef Exit = dynamic Function(int exitCode);

/// Update message
final updateMessage = [
  '${lightYellow.wrap('Update available!')} ',
  '${lightCyan.wrap(Pubspec.versionFull)} \u2192 ',
  '${lightCyan.wrap('{0}')}\n',
  '${lightYellow.wrap('Changelog:')} {1}\n',
  'Run ${lightCyan.wrap('${Pubspec.name} update')} to update',
].join();

/// Changelog link
final changelog = lightCyan.wrap(
  styleUnderlined.wrap(
    link(uri: Uri.parse('${Pubspec.repository}/releases/tag/kubeconfig-v{0}')),
  ),
);

/// {@template kubeconfig_command_runner}
/// A [CommandRunner] for the Kubeconfig CLI.
///
/// ```
/// $ kubeconfig --version
/// ```
/// {@endtemplate}
class KubeconfigCommandRunner extends CompletionCommandRunner<int> {
  /// {@macro kubeconfig_command_runner}
  KubeconfigCommandRunner({
    Logger? logger,
    io.ProcessSignal? sigint,
    Exit? exit,
    PubUpdater? pubUpdater,
  })  : _logger = logger ?? Logger(),
        _sigint = sigint ?? io.ProcessSignal.sigint,
        _exit = exit ?? io.exit,
        _pubUpdater = pubUpdater ?? PubUpdater(),
        super('kubeconfig', 'A kubeconfig utility.') {
    argParser.addDefaultRootFlags();
    addCommand(ConvertCommand(logger: _logger));
    addCommand(MergeCommand(logger: _logger));
    addCommand(ValidateCommand(logger: _logger));
  }

  final Logger _logger;
  final PubUpdater _pubUpdater;
  final io.ProcessSignal _sigint;
  final Exit _exit;

  @override
  Future<int> run(Iterable<String> args) async {
    late final ArgResults topLevelResults;
    try {
      topLevelResults = parse(args);
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }

    _sigint.watch().listen(_onSigint);

    late final int exitCode;
    try {
      exitCode = await runCommand(topLevelResults) ?? ExitCode.success.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    } catch (error) {
      _logger.err('$error');
      exitCode = ExitCode.software.code;
    }

    if (topLevelResults.command?.name != 'update' &&
        topLevelResults.command?.name != 'completion') {
      await _checkForUpdates();
    }

    return exitCode;
  }

  Future<void> _onSigint(io.ProcessSignal signal) async {
    await _checkForUpdates();
    _exit(0);
  }

  Future<void> _checkForUpdates() async {
    _logger.detail('[updater] checking for updates...');
    try {
      final latestVersion =
          await _pubUpdater.getLatestVersion(Pubspec.versionFull);
      final changelogLink = changelog!.format([latestVersion]);
      _logger.detail('[updater] latest version is $latestVersion.');

      final isUpToDate = Pubspec.versionFull == latestVersion;
      if (isUpToDate) {
        _logger.detail('[updater] no updates available.');
        return;
      }

      if (!isUpToDate) {
        _logger
          ..detail('[updater] update available.')
          ..info('')
          ..info(updateMessage.format([latestVersion, changelogLink]));
      }
    } catch (error, stackTrace) {
      _logger.detail(
        '[updater] update check error.\n$error\n$stackTrace',
      );
    } finally {
      _logger.detail('[updater] update check complete.');
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    if (topLevelResults['version'] == true) {
      _logger.info(Pubspec.versionFull);
      return ExitCode.success.code;
    }

    if (topLevelResults['verbose'] == true) {
      _logger.level = Level.verbose;
    }

    if (topLevelResults['update-from-pub'] == true) {
      final exitCode = await _updateFromPub();
      return exitCode;
    }

    _logger.detail('[meta] ${Pubspec.name} ${Pubspec.versionFull}');
    return super.runCommand(topLevelResults);
  }

  Future<int> _updateFromPub() async {
    final updateCheckProgress = _logger.progress('Checking for updates');
    late final String latestVersion;

    try {
      latestVersion = await _pubUpdater.getLatestVersion('kubeconfig');
    } catch (error) {
      updateCheckProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }

    updateCheckProgress.complete('Checked for updates');

    final isUpToDate = Pubspec.versionFull == latestVersion;

    if (isUpToDate) {
      _logger.info('kubeconfig is already at the latest version.');
      return ExitCode.success.code;
    }

    final updateProgress = _logger.progress('Updating to $latestVersion');
    late ProcessResult result;

    try {
      result = await _pubUpdater.update(
        packageName: 'kubeconfig',
        versionConstraint: latestVersion,
      );
    } catch (error) {
      updateProgress.fail();
      _logger.err('$error');
      return ExitCode.software.code;
    }

    if (result.exitCode != ExitCode.success.code) {
      updateProgress.fail();
      _logger.err('Error updating kubeconfig CLI: ${result.stderr}');
      return ExitCode.software.code;
    }

    updateProgress.complete('Updated to $latestVersion');

    return ExitCode.success.code;
  }
}

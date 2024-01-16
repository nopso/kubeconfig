import 'dart:async';

import 'package:kubeconfig_cli/src/commands/command_base.dart';
import 'package:kubeconfig_cli/src/commands/command_helper.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template validate_command}
/// Validate command.
/// {@endtemplate}
class ValidateCommand extends KubeconfigCommand {
  /// {@macro validate_command}
  ValidateCommand({super.logger, super.stdin, super.fs}) {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'The kubeconfig file to validate. It should be a file path or '
            '"-" for stdin.\n(mandatory)',
      )
      ..addOption(
        'json',
        abbr: 'j',
        help: 'If true, it considers the file or stdin content as JSON.',
        defaultsTo: 'false',
      );
  }

  @override
  String get name => 'validate';

  @override
  String get description => 'Validate a kubeconfig file.';

  @override
  Future<int> run() async {
    final contentResult =
        await getContent(results, logger, stdinn, fs, usageDescription);

    if (contentResult.item1 != ExitCode.success.code) {
      return contentResult.item1;
    }

    final kubeconfigResult = await getKubeconfig(
      results,
      contentResult.item2!,
      logger,
    );

    if (kubeconfigResult.item1 != ExitCode.success.code) {
      return kubeconfigResult.item1;
    }

    final validateResult = await validate(
      kubeconfigResult.item2!,
      logger,
    );

    return validateResult;
  }
}

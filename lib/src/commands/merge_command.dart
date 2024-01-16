import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:kubeconfig/kubeconfig.dart';
import 'package:kubeconfig_cli/src/commands/command_base.dart';
import 'package:kubeconfig_cli/src/commands/command_helper.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template merge_command}
/// Merge command.
/// {@endtemplate}
class MergeCommand extends KubeconfigCommand {
  /// {@macro merge_command}
  MergeCommand({super.logger, super.stdin, super.fs}) {
    argParser
      ..addOption(
        'files',
        abbr: 'f',
        help: 'List of paths to kubeconfig files to merge. The list should be '
            'colon-delimited for Linux and Mac, and semicolon-delimited for '
            'Windows.\n(mandatory)',
      )
      ..addOption(
        'json',
        abbr: 'j',
        help: 'If true, it considers files as JSON.',
        defaultsTo: 'false',
      )
      ..addOption(
        'indent',
        abbr: 'i',
        help: 'Number of spaces for JSON indentation.',
        defaultsTo: '2',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Write to file instead of stdout. It should be a file path.',
      )
      ..addOption(
        'validate',
        abbr: 'v',
        help: 'If true, it validates the kubeconfig files.',
        defaultsTo: 'true',
      );
  }

  @override
  String get name => 'merge';

  @override
  String get description => 'Merge kubeconfig files.';

  @override
  Future<int> run() async {
    final filesArg = results['files'];
    final jsonArg = results['json'];
    final indent = int.parse(results['indent'].toString());
    final outputArg = results['output'];
    final validateArg = results['validate'];

    if (filesArg == null || filesArg.toString().isEmpty) {
      logger
        ..err('Option "--files" is mandatory.')
        ..info('')
        ..info(usageDescription);
      return ExitCode.software.code;
    }

    if (!filesArg.toString().contains(pathDelimiter)) {
      logger.err('Make sure files are seperated by "$pathDelimiter".');
      return ExitCode.software.code;
    }

    final files = filesArg.toString().split(pathDelimiter)
      ..removeWhere((x) => x == '');

    if (files.length < 2) {
      logger.err('At least two kubeconfig files are required to merge.\n'
          'Make sure files are seperated by "$pathDelimiter".');
      return ExitCode.software.code;
    }

    if (files.length > 9) {
      logger.err('Too many kubeconfig files to merge. '
          'It should be less than 10.');
      return ExitCode.software.code;
    }

    Kubeconfig? kubeconfigMerged;

    for (var i = 0; i < files.length; i++) {
      final file = files[i].trim();
      String? content;

      try {
        content = await fs.file(file).readAsString();
      } on PathNotFoundException catch (e) {
        logger
          ..err('The path "$file" does not exist.')
          ..detail(e.toString());
        return ExitCode.software.code;
      }

      if (content.isNullOrEmpty) {
        logger.err('Empty file ("$file") content.');
        return ExitCode.software.code;
      }

      final kubeconfigResult = await getKubeconfig(
        results,
        content,
        logger,
      );

      if (kubeconfigResult.item1 != ExitCode.success.code) {
        return kubeconfigResult.item1;
      }

      final kubeconfigCurrent = kubeconfigResult.item2!;

      if (validateArg != null && validateArg.toString() == 'true') {
        final validateResult = await validate(
          kubeconfigCurrent,
          logger,
          logSuccess: false,
        );

        if (validateResult != ExitCode.success.code) {
          return validateResult;
        }
      }

      if (i == 0) {
        kubeconfigMerged = kubeconfigCurrent;
        continue;
      } else {
        try {
          // for testing purpose only
          if (results.name == 'throw-merge-exception') {
            throw Exception();
          }

          kubeconfigMerged = kubeconfigMerged!.merge(
            kubeconfigCurrent,
            validate: false,
            throwExceptions: true,
          );
        } catch (e) {
          logger
            ..err(
              'An unexpected error occurred when merging kubeconfig files. '
              'For details please use --verbose flag.',
            )
            ..detail(e.toString());
          return ExitCode.software.code;
        }
      }
    }

    String? content;

    if (jsonArg != null && jsonArg.toString() == 'true') {
      final jsonEncoder = JsonEncoder.withIndent(' ' * indent);
      content = jsonEncoder.convert(kubeconfigMerged!.toJson());
    } else {
      content = kubeconfigMerged!.toYaml();
    }

    if (outputArg != null) {
      try {
        // for testing purpose only
        if (results.name == 'throw-file-exception') {
          throw Exception();
        }

        await fs.file(outputArg.toString()).writeAsString(content);
      } catch (e) {
        logger
          ..err(
            'An unexpected error occurred when saving file. For details '
            'please use --verbose flag.',
          )
          ..detail(e.toString());
        return ExitCode.software.code;
      }
    } else {
      logger.write(content);
    }

    return ExitCode.success.code;
  }
}

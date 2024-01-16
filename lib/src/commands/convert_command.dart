import 'dart:async';
import 'dart:convert';

import 'package:kubeconfig/kubeconfig.dart';
import 'package:kubeconfig_cli/src/commands/command_base.dart';
import 'package:kubeconfig_cli/src/commands/command_helper.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:yaml/yaml.dart';

/// {@template convert_command}
/// Convert command.
/// {@endtemplate}
class ConvertCommand extends KubeconfigCommand {
  /// {@macro convert_command}
  ConvertCommand({super.logger, super.stdin, super.fs}) {
    argParser
      ..addOption(
        'file',
        abbr: 'f',
        help: 'The kubeconfig file to convert. It should be a file path or '
            '"-" for stdin.\n(mandatory)',
      )
      ..addOption(
        'json',
        abbr: 'j',
        help: 'If true, it considers the file or stdin content as JSON.',
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
        help: 'If true, it validates the kubeconfig file.',
        defaultsTo: 'true',
      );
  }

  @override
  String get name => 'convert';

  @override
  String get description => 'Convert a kubeconfig file.';

  @override
  Future<int> run() async {
    final jsonArg = results['json'];
    final indent = int.parse(results['indent'].toString());
    final outputArg = results['output'];
    final validateArg = results['validate'];
    final contentResult = await getContent(
      results,
      logger,
      stdinn,
      fs,
      usageDescription,
    );

    if (contentResult.item1 != ExitCode.success.code) {
      return contentResult.item1;
    }

    if (validateArg != null && validateArg.toString() == 'true') {
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
        logSuccess: false,
      );

      if (validateResult != ExitCode.success.code) {
        return validateResult;
      }
    }

    String? content;

    try {
      // for testing purpose only
      if (results.name == 'throw-convert-exception') {
        throw Exception();
      }

      if (jsonArg != null && jsonArg.toString() == 'true') {
        content = (json.decode(contentResult.item2!) as Map<String, dynamic>)
            .toYaml();
      } else {
        final jsonEncoder = JsonEncoder.withIndent(' ' * indent);
        content = jsonEncoder.convert(loadYaml(contentResult.item2!));
      }
    } catch (e) {
      logger
        ..err(
          'An unexpected error occurred when converting file content. '
          'For details please use --verbose flag.',
        )
        ..detail(e.toString());
      return ExitCode.software.code;
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

import 'dart:convert';
import 'dart:io' hide stdin;

import 'package:args/args.dart';
import 'package:file/file.dart';
import 'package:kubeconfig/kubeconfig.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:tuple/tuple.dart';

/// Path delimiter for OS. It is ":" for macOS and Linux, ";" for Windows.
final pathDelimiter = Platform.isWindows ? ';' : ':';

/// Gets content from a kubeconfig file or input.
Future<Tuple2<int, String?>> getContent(
  ArgResults results,
  Logger logger,
  Stdin stdin,
  FileSystem fs,
  String usageString,
) async {
  final fileArg = results['file'];
  String? content;

  if (fileArg == null || fileArg.toString().isEmpty) {
    logger
      ..err('Option "--file" is mandatory.')
      ..info('')
      ..info(usageString);
    return Tuple2<int, String?>(ExitCode.software.code, null);
  }

  if (fileArg == '-') {
    content = stdin.readLineSync();
    logger
      ..detail('Validating the following input:')
      ..detail(content);
  } else {
    try {
      content = await fs.file(fileArg.toString()).readAsString();
    } on PathNotFoundException catch (e) {
      logger
        ..err('The path "$fileArg" does not exist.')
        ..detail(e.toString());
      return Tuple2<int, String?>(ExitCode.software.code, null);
    }

    logger
      ..detail('Validating the following file:')
      ..detail(fileArg.toString());
  }

  if (content.isNullOrEmpty) {
    logger.err('Empty file or input content.');
    return Tuple2<int, String?>(ExitCode.software.code, null);
  }

  return Tuple2<int, String?>(ExitCode.success.code, content);
}

/// Gets a kubeconfig object from string content.
Future<Tuple2<int, Kubeconfig?>> getKubeconfig(
  ArgResults results,
  String content,
  Logger logger, {
  bool logSuccess = true,
}) async {
  final jsonArg = results['json'];
  Kubeconfig kubeconfig;

  if (jsonArg != null && jsonArg.toString() == 'true') {
    try {
      kubeconfig =
          Kubeconfig.fromJson(json.decode(content) as Map<String, dynamic>);
    } catch (e) {
      logger
        ..err('Invalid file or input.')
        ..detail(e.toString());
      return Tuple2<int, Kubeconfig?>(ExitCode.software.code, null);
    }
  } else {
    try {
      kubeconfig = Kubeconfig.fromYaml(content);
    } catch (e) {
      logger
        ..err('Invalid file or input.')
        ..detail(e.toString());
      return Tuple2<int, Kubeconfig?>(ExitCode.software.code, null);
    }
  }

  return Tuple2<int, Kubeconfig?>(ExitCode.success.code, kubeconfig);
}

/// Validates a kubeconfig file or input.
Future<int> validate(
  Kubeconfig kubeconfig,
  Logger logger, {
  bool logSuccess = true,
}) async {
  try {
    final validationResult = kubeconfig.validate();

    if (validationResult.code == ValidationCode.valid) {
      if (logSuccess) logger.success(validationResult.description);
      return ExitCode.success.code;
    } else {
      logger.err(validationResult.description);
      return ExitCode.software.code;
    }
  } catch (e) {
    logger
      ..err(
        'An unexpected error occurred. '
        'For details please use --verbose flag.',
      )
      ..detail(e.toString());
    return ExitCode.software.code;
  }
}

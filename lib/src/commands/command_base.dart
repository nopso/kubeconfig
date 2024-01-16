import 'dart:io';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template kubeconfig_command}
/// The base class for all kubeconfig executable commands.
/// {@endtemplate}
abstract class KubeconfigCommand extends Command<int> {
  /// {@macro kubeconfig_command}
  KubeconfigCommand({Logger? logger, Stdin? stdin, FileSystem? fs})
      : _logger = logger,
        _stdin = stdin,
        _fs = fs;

  /// [ArgResults] used for testing purposes only.
  @visibleForTesting
  ArgResults? testArgResults;

  /// Usage [String] used for testing purposes only.
  @visibleForTesting
  String? testUsage;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;

  /// Usage description.
  String get usageDescription => testUsage ?? usage;

  /// [Logger] instance used to wrap stdout.
  Logger get logger => _logger ??= Logger();

  Logger? _logger;

  /// [Stdin] instance used to wrap stdin.
  Stdin get stdinn => _stdin ??= stdin;

  Stdin? _stdin;

  /// [FileSystem] instance used to wrap stdout.
  FileSystem get fs => _fs ??= const LocalFileSystem();

  FileSystem? _fs;
}

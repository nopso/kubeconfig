import 'package:args/args.dart';

/// Flag extensions
extension FlagX on ArgParser {
  /// Adds default flags
  void addDefaultRootFlags() {
    addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
      abbr: 'v',
    );
    addFlag(
      'verbose',
      negatable: false,
      help: 'Output additional logs.',
    );

    addFlag(
      'update-from-pub',
      negatable: false,
      help: 'Update kubeconfig CLI from pub.dev\n(if installed with '
          '"dart pub global activate kubeconfig" command).',
    );
  }
}

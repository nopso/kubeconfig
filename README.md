[![Kubeconfig logo][kubeconfig_logo]][kubeconfig_link]

[![CI][ci_badge]][ci_link]
[![Coverage][coverage_badge]][coverage_link]
[![License: MIT][license_badge]][license_link]

---

`kubeconfig` is a command-line tool that simplifies the management of kubeconfig files. It offers a bunch of features, such as validating, merging, and converting kubeconfig files, to ensure that you have a consistent and optimized configuration for accessing multiple Kubernetes clusters.

Developed with 💙 by [Nopso][nopso_link]

## Features

- **Validate**: Check the syntax and structure of kubeconfig files for common errors or inconsistencies.
- **Convert**: Convert between different formats (YAML to JSON or JSON to YAML).
- **Merge**: Combine multiple kubeconfig files into a single file, preserving context and cluster information, and avoiding duplication.

## Installation
### From Homebrew (macOS or Linux)

If you use [the Homebrew package manager][homebrew], you
can install `kubeconfig` by running

```sh
brew install kubeconfig/kubeconfig/kubeconfig
```

That'll give you a `kubeconfig` executable on your command line.

### From Chocolatey or Scoop (Windows)

If you use [the Chocolatey package manager][chocolatey]
or [the Scoop package manager][scoop] for
Windows, you can install `kubeconfig` by running

```cmd
choco install kubeconfig
```

or

```cmd
scoop install kubeconfig
```

That'll give you a `kubeconfig` executable on your command line.

### Standalone

You can download the standalone `kubeconfig` archive for your operating
system—containing the Dart VM and the snapshot of the executable—from [the
GitHub release page][releases_page]. Extract it, [add the directory to your path][add_the_directory_to_your_path], restart
your terminal, and the `kubeconfig` executable is ready to run!

## Usage

Once you've installed the kubeconfig, run `kubeconfig --help` for more info:

```sh
Usage: kubeconfig <command> [arguments]

Global options:
-h, --help               Print this usage information.
-v, --version            Print the current version.
    --verbose            Output additional logs.
    --update-from-pub    Update kubeconfig CLI from pub.dev
                         (if installed with "dart pub global activate kubeconfig" command).

Available commands:
  convert    Convert a kubeconfig file.
  merge      Merge kubeconfig files.
  validate   Validate a kubeconfig file.

Run "kubeconfig help <command>" for more information about a command.
```

[kubeconfig_logo]: assets/logo.svg
[kubeconfig_link]: https://kubeconfig.nopso.io/
[ci_badge]: https://github.com/nopso/kubeconfig/actions/workflows/ci.yml/badge.svg?branch=main
[ci_link]: https://github.com/nopso/kubeconfig/actions/workflows/ci.yml
[coverage_badge]: https://codecov.io/github/nopso/kubeconfig/graph/badge.svg?token=7SYUSR452C
[coverage_link]: https://codecov.io/github/nopso/kubeconfig
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[nopso_link]: https://nopso.io/
[docs_link]: https://kubeconfig.nopso.io/
[releases_page]: https://github.com/nopso/kubeconfig/releases/
[add_the_directory_to_your_path]: https://katiek2.github.io/path-doc/
[homebrew]: https://brew.sh
[scoop]: https://scoop.sh
[chocolatey]: https://chocolatey.org

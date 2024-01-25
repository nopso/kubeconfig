[![Kubeconfig logo][kubeconfig_logo]][kubeconfig_link]

[![CI][ci_badge]][ci_link]
[![Coverage][coverage_badge]][coverage_link]
[![License: MIT][license_badge]][license_link]

---
`kubeconfig` is a command-line tool that simplifies the management of kubeconfig files. It offers a bunch of features, such as validating, merging, and converting kubeconfig files, to ensure that you have a consistent and optimized configuration for accessing multiple Kubernetes clusters.

Developed with 💙 by [Fatih Sever][fatihsever_link]

## Features
- **Validate**: Check the syntax and structure of kubeconfig files for common errors or inconsistencies.
- **Convert**: Convert between different formats (YAML to JSON or JSON to YAML).
- **Merge**: Combine multiple kubeconfig files into a single file, preserving context and cluster information, and avoiding duplication.

## Installation
### macOS

`kubeconfig` is available via [Homebrew][], [MacPorts][], [Conda][], [Spack][], and as a downloadable binary from the [releases_page][].

#### Homebrew

| Install:          | Upgrade:          |
| ----------------- | ----------------- |
| `brew install kubeconfig` | `brew upgrade kubeconfig` |

#### MacPorts

| Install:               | Upgrade:                                       |
| ---------------------- | ---------------------------------------------- |
| `sudo port install kubeconfig` | `sudo port selfupdate && sudo port upgrade kubeconfig` |

#### Conda

| Install:                                 | Upgrade:                                |
|------------------------------------------|-----------------------------------------|
| `conda install kubeconfig --channel conda-forge` | `conda update kubeconfig --channel conda-forge` |

Additional Conda installation options available on the [kubeconfig-feedstock page](https://github.com/conda-forge/kubeconfig-feedstock#installing-kubeconfig).

#### Spack

| Install:           | Upgrade:                                 |
| ------------------ | ---------------------------------------- |
| `spack install kubeconfig` | `spack uninstall kubeconfig && spack install kubeconfig` |

### Linux & BSD

`kubeconfig` is available via:
- [our Debian and RPM repositories](./docs/install_linux.md);
- community-maintained repositories in various Linux distros;
- OS-agnostic package managers such as [Homebrew](#homebrew), [Conda](#conda), and [Spack](#spack); and
- our [releases_page][] as precompiled binaries.

For more information, see [Linux & BSD installation](./docs/install_linux.md).

### Windows

`kubeconfig` is available via [WinGet][], [scoop][], [Chocolatey][], [Conda](#conda), and as downloadable MSI.

#### WinGet

| Install:            | Upgrade:            |
| ------------------- | --------------------|
| `winget install --id GitHub.cli` | `winget upgrade --id GitHub.cli` |

> **Note**
> The Windows installer modifies your PATH. When using Windows Terminal, you will need to **open a new window** for the changes to take effect. (Simply opening a new tab will _not_ be sufficient.)

#### scoop

| Install:           | Upgrade:           |
| ------------------ | ------------------ |
| `scoop install kubeconfig` | `scoop update kubeconfig`  |

#### Chocolatey

| Install:           | Upgrade:           |
| ------------------ | ------------------ |
| `choco install kubeconfig` | `choco upgrade kubeconfig` |

#### Signed MSI

MSI installers are available for download on the [releases_page][].

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
[kubeconfig_link]: https://kubeconfig.pages.dev/
[ci_badge]: https://github.com/fatihsever/kubeconfig/actions/workflows/ci.yml/badge.svg?branch=main
[ci_link]: https://github.com/fatihsever/kubeconfig/actions/workflows/ci.yml
[coverage_badge]: https://codecov.io/github/fatihsever/kubeconfig/graph/badge.svg?token=7SYUSR452C
[coverage_link]: https://codecov.io/github/fatihsever/kubeconfig
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[fatihsever_link]: https://fatihsever.com/
[docs_link]: https://kubeconfig.pages.dev/
[releases_page]: https://github.com/fatihsever/kubeconfig/releases/latest
[Homebrew]: https://brew.sh
[MacPorts]: https://www.macports.org
[winget]: https://github.com/microsoft/winget-cli
[scoop]: https://scoop.sh
[Chocolatey]: https://chocolatey.org
[Conda]: https://docs.conda.io/en/latest/
[Spack]: https://spack.io

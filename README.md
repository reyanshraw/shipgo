# shipgo

> Cross-platform Git push tool — safe, scriptable, agent-friendly.

[![CI](https://github.com/reyanshraw/shipgo/actions/workflows/ci.yml/badge.svg)](https://github.com/reyanshraw/shipgo/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://github.com/reyanshraw/shipgo/actions/workflows/scorecard.yml/badge.svg)](https://github.com/reyanshraw/shipgo/actions/workflows/scorecard.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

shipgo helps you push, sync, tag, and open PRs without losing safety. It provides a Bash implementation for Unix-like systems, a PowerShell version for Windows, and a batch wrapper for CMD.

## Features

- Safe default behavior for Git operations
- `--force-with-lease` instead of bare force pushes
- Push, sync, remote branch, tag, PR, and release helpers
- Cross-platform CLI surface (`shipgo.sh`, `shipgo.ps1`, `shipgo.bat`)
- Scriptable commands suitable for automation and agent workflows

## Installation

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/reyanshraw/shipgo/main/shipgo.sh -o /usr/local/bin/shipgo
chmod +x /usr/local/bin/shipgo
```

Or from a cloned checkout:

```bash
git clone https://github.com/reyanshraw/shipgo.git
cd shipgo
chmod +x shipgo.sh
sudo cp shipgo.sh /usr/local/bin/shipgo
```

### Windows (PowerShell)

```powershell
git clone https://github.com/reyanshraw/shipgo.git
cd shipgo
Copy-Item .\shipgo.ps1 $env:USERPROFILE\bin\shipgo.ps1
```

Then run:

```powershell
shipgo help
```

### Windows (CMD)

```cmd
git clone https://github.com/reyanshraw/shipgo.git
cd shipgo
shipgo.bat help
```

## Quick start

```bash
shipgo status
shipgo push
shipgo up
shipgo sync
shipgo tag v1.2.0
shipgo release v1.2.0
shipgo pr "Add dark mode"
```

## Commands

See the full command reference in [docs/commands.md](docs/commands.md).

Core examples:

```bash
shipgo push
shipgo up
shipgo all
shipgo tags
shipgo force
shipgo dry
shipgo sync
shipgo pull
shipgo tag v1.2.0 "Release v1.2.0"
shipgo release v1.2.0
shipgo pr "Add dark mode"
shipgo help
```

## Configuration

Shipgo reads a config file from `~/.shipgorc` unless `SHIPGO_CONFIG` is set.

Example:

```bash
DEFAULT_REMOTE="origin"
PROTECTED_BRANCHES="main master develop"
CONFIRM_FORCE=true
```

```bash
SHIPGO_YES=1 shipgo force
```

See [docs/configuration.md](docs/configuration.md) for details.

## Documentation

- [docs/commands.md](docs/commands.md)
- [docs/configuration.md](docs/configuration.md)
- [docs/architecture.md](docs/architecture.md)
- [AGENTS.md](AGENTS.md)

## Development

```bash
make lint
make test
```

Or directly:

```bash
bash scripts/test.sh
bash scripts/lint.sh
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing.

## Security

- Shipgo avoids bare `--force`; it prefers `--force-with-lease`.
- Protected branches are checked against `main`, `master`, and `develop` by default.
- Never commit credentials or secrets.

## License

This project is licensed under the [MIT License](LICENSE).

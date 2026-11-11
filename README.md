# shipgo

> Cross-platform Git push tool — safe, scriptable, agent-friendly.

[![CI](https://github.com/reyanshraw/shipgo/actions/workflows/ci.yml/badge.svg)](https://github.com/reyanshraw/shipgo/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://github.com/reyanshraw/shipgo/actions/workflows/scorecard.yml/badge.svg)](https://github.com/reyanshraw/shipgo/actions/workflows/scorecard.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

shipgo is a cross-platform Git workflow helper built for safe, repeatable, and automation-friendly development. It helps you push, sync, tag, and manage pull requests without the unsafe defaults that often lead to accidental overwrites.

It ships as:
- a Bash script for macOS/Linux
- a PowerShell script for Windows
- a batch wrapper for CMD

This makes shipgo useful for everyday developer workflows, CI automation, and AI-assisted coding environments.

## Why shipgo?

Git is powerful, but many common actions are repetitive and easy to get wrong. shipgo simplifies the workflow while keeping safety in mind:

- safer push behavior by default
- force pushes use `--force-with-lease`
- common repo tasks are wrapped in one CLI
- works consistently across major operating systems
- designed for scripting and automation

## Features

- Safe default behavior for Git operations
- `--force-with-lease` instead of bare force pushes
- Push, sync, remote branch, tag, PR, and release helpers
- Cross-platform CLI surface: `shipgo.sh`, `shipgo.ps1`, `shipgo.bat`
- Scriptable commands for automation and agent workflows
- Clean developer experience with minimal friction

## Installation

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/reyanshraw/shipgo/main/shipgo.sh -o /usr/local/bin/shipgo
chmod +x /usr/local/bin/shipgo
```

Or install from a local clone:

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

Common examples:

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

## Typical workflows

### Check repository status

```bash
shipgo status
```

### Push current branch safely

```bash
shipgo push
```

### Sync and update your branch

```bash
shipgo up
shipgo sync
```

### Create a tag

```bash
shipgo tag v1.2.0
shipgo tag v1.2.0 "Release v1.2.0"
```

### Create a release

```bash
shipgo release v1.2.0
```

### Open a pull request

```bash
shipgo pr "Add dark mode"
```

## Configuration

Shipgo reads configuration from `~/.shipgorc` unless `SHIPGO_CONFIG` is set.

Example:

```bash
DEFAULT_REMOTE="origin"
PROTECTED_BRANCHES="main master develop"
CONFIRM_FORCE=true
```

You can override behavior for a single command:

```bash
SHIPGO_YES=1 shipgo force
```

See [docs/configuration.md](docs/configuration.md) for more details.

## Documentation

- [docs/commands.md](docs/commands.md)
- [docs/configuration.md](docs/configuration.md)
- [docs/architecture.md](docs/architecture.md)
- [AGENTS.md](AGENTS.md)

## Development

Run linting and tests:

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

Contributions are welcome. Please read:

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)

## Security

Shipgo is built with safer Git defaults:

- avoids bare `--force`
- prefers `--force-with-lease`
- checks protected branches like `main`, `master`, and `develop`
- encourages safe automation and human review

Never commit credentials or secrets.

## License

This project is licensed under the [MIT License](LICENSE).

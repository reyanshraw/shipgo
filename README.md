# shipgo

> Cross-platform Git push tool — safe, scriptable, agent-friendly.

[![CI](https://github.com/ORG/shipgo/actions/workflows/ci.yml/badge.svg)](https://github.com/ORG/shipgo/actions/workflows/ci.yml)
[![OpenSSF Scorecard](https://github.com/ORG/shipgo/actions/workflows/scorecard.yml/badge.svg)](https://github.com/ORG/shipgo/actions/workflows/scorecard.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Install

```bash
brew install ORG/tap/shipgo
bat
scoop install shipgo
bash
chmod +x shipgo.sh && sudo cp shipgo.sh /usr/local/bin/shipgo
Quick start
bash
shipgo push
shipgo sync
shipgo pr "Add dark mode"
shipgo release v1.2.0
Commands
See docs/commands.md.

Configuration
See docs/configuration.md.

Contributing
See CONTRIBUTING.md. Read AGENTS.md before using AI agents.

License
MIT — see LICENSE.

text

---

## `CONTRIBUTING.md`

```markdown
# Contributing to shipgo

Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) first.

## Setup

```bash
git clone https://github.com/ORG/shipgo.git
cd shipgo
chmod +x shipgo.sh
Development
bash
make lint
make test
Pull requests
Fork, branch as feat/<slug> or fix/<issue>.

Add tests where behavior changes.

Run make lint test locally.

Open a PR against main.

CI must pass; one maintainer approval required.

Commit style
Conventional Commits: feat:, fix:, docs:, chore:, refactor:, test:.

text

---

## `CODE_OF_CONDUCT.md`

```markdown
# Contributor Covenant Code of Conduct

This project follows the [Contributor Covenant v2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## Reporting

Email conduct@ORG.dev. All reports are reviewed and handled confidentially.
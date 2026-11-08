# Contributing to shipgo

Read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) first.

## Setup

git clone https://github.com/ORG/shipgo.git
cd shipgo
chmod +x shipgo.sh

## Development

make lint
make test

## Pull requests

1. Fork, branch as `feat/<slug>` or `fix/<issue>`.
2. Add tests where behavior changes.
3. Run `make lint test` locally.
4. Open a PR against `main`.
5. CI must pass; one maintainer approval required.

## Commit style

Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
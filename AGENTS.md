# Agent Guide — shipgo

## Overview
`shipgo` is a shell + PowerShell CLI wrapping Git push workflows.
Primary files: `shipgo.sh`, `shipgo.bat`, `shipgo.ps1`, `shipgo-completion.bash`.

## Build / test
```bash
make lint
make test
bash scripts/test.sh
Code style
Bash: shellcheck -x, 2-space indent, set -uo pipefail.

PowerShell: PSScriptAnalyzer, approved verbs.

CMD: no delayed expansion unless required.

Testing
Run tests/test-syntax.sh on every change. Matrix: Ubuntu, macOS, Windows.

Security
Always --force-with-lease; never bare --force.

Never commit credentials or tokens.

All AI write actions pass the Safety Gate in .github/repo-policy.yml.

Commit / PR rules
Conventional Commits.

PRs must reference an issue and pass CI.

main is protected; use fix/* or feat/*.

Agent boundaries
Read: any file.

Write: only via .github/workflows/ai-*.yml.

Never push directly to main.
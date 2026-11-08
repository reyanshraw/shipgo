# Configuration

Config file: `~/.shipgorc` (override via `SHIPGO_CONFIG`).

```bash
DEFAULT_REMOTE="origin"
PROTECTED_BRANCHES="main master develop"
CONFIRM_FORCE=true
Env: SHIPGO_YES=1 skips all confirmations.

text

## `docs/architecture.md`

```markdown
# Architecture

- Three shells: `shipgo.sh`, `shipgo.bat`, `shipgo.ps1` — identical command surface.
- Each calls `git` directly; no wrappers around git beyond safety checks.
- Force push: always `--force-with-lease`, never bare `--force`.
- Menu and subcommands share the same underlying function per action.
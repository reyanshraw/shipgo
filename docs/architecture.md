# Architecture

- Three shells: `shipgo.sh`, `shipgo.bat`, `shipgo.ps1` — identical command surface.
- Each calls `git` directly; no wrappers around git beyond safety checks.
- Force push: always `--force-with-lease`, never bare `--force`.
- Menu and subcommands share the same underlying function per action.
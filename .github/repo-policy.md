# Product Guardrails
- Privacy by default
- Simplicity over features

# Risk Classification
## Always High Risk
- Auth/authorization changes
- Force-push logic
- Release or distribution scripts

## Always Low Risk
- Documentation-only changes
- Test-only changes

# Decision Rules
## Bugs
- Fix if reproducible or obvious
## Features
- Accept if it benefits most users
## External PRs
- The idea matters, the exact code doesn't

# Repo-Specific Rules
- Treat changes to `shipgo.ps1` as risk:high
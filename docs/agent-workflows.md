# Agent Workflows

- Policy Agent (read + guarded write): `ai-triage.yml`, `ai-maintainer.yml`
- Gate Runner (pure logic): `ci.yml`, `ai-ci-repair.yml`, `ai-pr-review.yml`
- Release Runner (pure logic): `release.yml`, `ai-release.yml`

Rules:
- `ai-triage` and `ai-pr-review` are read-only on contents.
- Write permissions only via `ai-maintainer` and `ai-ci-repair`, scoped to bot branches.
- No auto-merge in v1.
- Policy is human-owned in `.github/repo-policy.md`.
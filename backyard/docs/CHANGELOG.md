# Changelog

Releases of backyard, newest first. A new major says how to take it in [MIGRATING.md](MIGRATING.md).

## 4.0.0 (2026-11-25)
**Breaking:** garden is renamed **backyard** ([decision 0005](decisions/0005-backyard.md), [migrating](MIGRATING.md)). `seeds-format` stays 2.0.
- The router skill is `backyard`, the framework folder `backyard/`, its skills `backyard-memory`, `backyard-escalate`, `backyard-handoff`, `backyard-sync` and `backyard-new-seed`.
- `backyard` and `backyard-*` are reserved for backyard's skills; `garden` and `garden-*` are free.
- The repo is [noueii/backyard](https://github.com/noueii/backyard); the CI workflow is `.github/workflows/backyard.yml`.
- Staged branches are `backyard/*`, stages live in `~/.local/state/backyard/`, and the scripts read `BACKYARD_DRY` and `BACKYARD_NO_GH`.
- The root `README.md` and `AGENTS.md` placeholders name `backyard`.

Earlier releases (1.0.0 to 3.0.0, as garden) are described in [MIGRATING.md](MIGRATING.md) and the [decisions](decisions/README.md).

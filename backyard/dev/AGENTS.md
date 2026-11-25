# Maintaining noueii/backyard

For changes to backyard itself (upstream), not to a user's backyard. Work on a branch of noueii/backyard and edit directly: the user-facing rules in the root `AGENTS.md` (stage through memory's stage.md, memory through write.py) are for users' backyards.

- **The framework stays in `backyard/`** (`backyard/docs/decisions/0002-framework-folder.md`). backyard owns `SKILL.md`, `backyard/` and the root exceptions in `backyard/docs/upstream-paths.txt`, each justified there; add nothing else at the root. A new framework skill or `backyard/` folder also goes into `FRAMEWORK_SKILLS` or `FRAMEWORK_DIRS` in `backyard/check/validate.py`.
- **Decisions** go in `backyard/docs/decisions/` (`NNNN-<slug>.md`, listed in its README). Change the format only with a decision record, a `backyard/docs/SPEC.md` update, and a validator change in the same PR.
- **Keep the user-owned placeholders frozen** (`README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/INDEX.md`, `seeds/INDEX.md`, `memory/INDEX.md`): `backyard/dev/check-upstream.sh` checks them by hash, so a release never touches a user's files. Ship no seeds, docs, memory or root `skills/`. The framework's own README is `backyard/docs/README.md`.
- **Checks, all deterministic (CI runs the first four):**
  - `python3 backyard/check/validate.py .`
  - `bash backyard/dev/check-upstream.sh` (the frozen placeholders, and every shipped file backyard-owned or a placeholder)
  - `bash backyard/dev/test-validate.sh` (fixtures in `backyard/dev/fixtures/`: shell overlays on a temp copy; `# expect: ok` or a message)
  - `bash backyard/dev/test-scripts.sh` (write.py, block.sh, call.sh, check.sh, sync.sh in temp repos)
  - `bash backyard/dev/prove-access.sh` and `bash backyard/dev/prove-install.sh` need the tools installed, so they run on a maintainer's machine, in a temp HOME, against `backyard/dev/fake-model.py`. prove-install clones the committed HEAD, so commit first. Run them when you change `backyard/skills/backyard-handoff/`, the router's frontmatter, the layout, or anything about discovery, and update `backyard/skills/backyard-handoff/access.md` and the decision record with what they show.
- **No AI evals, plugins, CLI or runtime.** A script lives inside the skill that uses it, and only for a real guarantee (the question block, access enforcement, the memory gate, sync's memory-only pushes).
- **Budgets** (`backyard/docs/SPEC.md` §7) apply to backyard's own skills too: a skill's SKILL.md body is at most 800 words, a supporting file at most 300 lines.
- **Releases:** bump `metadata.version` in `SKILL.md`, then tag `v<version>` after the merge; users' `backyard-sync` takes the newest tag of their major. A new major (of `version` or `seeds-format`) needs a `backyard/docs/MIGRATING.md` section.
- Never install into your real HOME to test: the proofs use a temp HOME.

# Maintaining noueii/garden

For changes to garden itself (upstream), not to a user's garden. Work on a branch of noueii/garden and edit directly: the user-facing rules in the root `AGENTS.md` (stage through rsi, memory through write.py) are for users' gardens.

- **The framework stays in `garden/`** (`garden/docs/decisions/0002-framework-folder.md`). garden owns `SKILL.md`, `garden/` and the root exceptions in `garden/docs/upstream-paths.txt`, each justified there; add nothing else at the root. A new framework skill or `garden/` folder also goes into `FRAMEWORK_SKILLS` or `FRAMEWORK_DIRS` in `garden/check/validate.py`.
- **Decisions** go in `garden/docs/decisions/` (`NNNN-<slug>.md`, listed in its README). Change the format only with a decision record, a `garden/docs/SPEC.md` update, and a validator change in the same PR.
- **Keep the user-owned placeholders frozen** (`README.md`, `AGENTS.md`, `CLAUDE.md`, `docs/INDEX.md`, `seeds/INDEX.md`, `MEMORY.md`, `memory/.gitkeep`): `garden/dev/check-upstream.sh` checks them by hash, so a release never touches a user's files. Ship no seeds, docs, memory or root `skills/`. The framework's own README is `garden/docs/README.md`.
- **Checks, all deterministic (CI runs the first four):**
  - `python3 garden/check/validate.py .`
  - `bash garden/dev/check-upstream.sh` (the frozen placeholders, and every shipped file garden-owned or a placeholder)
  - `bash garden/dev/test-validate.sh` (fixtures in `garden/dev/fixtures/`: shell overlays on a temp copy; `# expect: ok` or a message)
  - `bash garden/dev/test-scripts.sh` (write.py, block.sh, call.sh, check.sh, sync.sh in temp repos)
  - `bash garden/dev/prove-access.sh` and `bash garden/dev/prove-install.sh` need the tools installed, so they run on a maintainer's machine, in a temp HOME, against `garden/dev/fake-model.py`. prove-install clones the committed HEAD, so commit first. Run them when you change `garden/skills/handoff/`, the router's frontmatter, the layout, or anything about discovery, and update `garden/skills/handoff/access.md` and the decision record with what they show.
- **No AI evals, plugins, CLI or runtime.** A script lives inside the skill that uses it, and only for a real guarantee (the question block, access enforcement, the memory gate, sync's memory-only pushes).
- **Budgets** (`garden/docs/SPEC.md` §7) apply to garden's own skills too: an ENTRY.md body is at most 800 words, a supporting file at most 300 lines.
- **Releases:** bump `metadata.version` in `SKILL.md`, then tag `v<version>` after the merge; users' `sync` takes the newest tag of their major. A new major (of `version` or `seeds-format`) needs a `garden/docs/MIGRATING.md` section.
- Never install into your real HOME to test: the proofs use a temp HOME.

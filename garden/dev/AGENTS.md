# Maintaining noueii/garden

For changes to garden itself (upstream), not to a user's garden.

- **Decisions** go in `dev/decisions/` (`NNNN-<slug>.md`, listed in its README). Change the format only with a decision record, a `spec/SPEC.md` update, and a validator change in the same PR.
- **Keep the user-owned placeholders frozen** (`docs/INDEX.md`, `seeds/INDEX.md`, `MEMORY.md`, `memory/.gitkeep`): `dev/check-upstream.sh` checks them by hash, so a release never touches a user's files. Ship no seeds, docs or memory.
- **Checks, all deterministic (CI runs the first four):**
  - `python3 check/validate.py .`
  - `bash dev/check-upstream.sh`
  - `bash dev/test-validate.sh` (fixtures in `dev/fixtures/`: shell overlays on a temp copy; `# expect: ok` or a message)
  - `bash dev/test-scripts.sh` (write.py, block.sh, call.sh, check.sh, sync.sh in temp repos)
  - `bash dev/prove-access.sh` and `bash dev/prove-install.sh` need the tools installed, so they run on a maintainer's machine, in a temp HOME, against `dev/fake-model.py`. Run them when you change `skills/handoff/`, the router's frontmatter, or anything about discovery, and update `skills/handoff/access.md` and the decision record with what they show.
- **No AI evals, plugins, CLI or runtime.** A script lives inside the skill that uses it, and only for a real guarantee (the question block, access enforcement, the memory gate, sync's memory-only pushes).
- **Budgets** (`spec/SPEC.md` §7) apply to garden's own skills too: an ENTRY.md body is at most 800 words, a supporting file at most 300 lines.
- **Releases:** bump `metadata.version` in `SKILL.md`, then tag `v<version>` after the merge; users' `sync` takes the newest tag of their major. A new `seeds-format` major needs a `spec/MIGRATING.md` section.
- Never install into your real HOME to test: the proofs use a temp HOME.

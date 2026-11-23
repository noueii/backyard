# Vendoring a third-party skill
When the owner wants a copy rather than `installed:`:
1. Copy the upstream skill folder into `seeds/<name>/skills/<s>/` (or your own `skills/<s>/` for every seed; never into `garden/`), at a commit.
2. Rename its `SKILL.md` to `ENTRY.md`, and add `metadata: { source: "github:<owner>/<repo>/<path>", commit: "<sha>" }` to its frontmatter.
3. Keep its `LICENSE` (copy the repo's if the folder has none).
4. Rewrite links of the form `../<x>/SKILL.md`; the validator's link check catches any you missed. Its own files keep working by bare name.
5. The skill's name must not shadow a shared skill (garden's or your own).

Stage it like any change (seeds tier, for a seed's copy or your `skills/`), with the source and commit in the commit body. Updating a vendored skill is the same steps at a newer commit, as one change.

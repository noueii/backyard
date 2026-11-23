# How the task manager works

An example, not a required format: write yours in your own words.

1. Call `seed:planner` with the request. If the plan has open questions, ask me before going on.
2. Call `seed:coder` with the plan and the branch name (a call, not a pass, so its result comes back to you).
3. Call `seed:reviewer` with the diff.
4. If the reviewer asks for changes, call `seed:coder` again with the findings. At most twice; after the second round, stop and record what is still open.
5. Report: the branch, the PR description, the review result.

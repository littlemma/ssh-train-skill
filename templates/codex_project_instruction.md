# Codex Project Instructions

- Edit code only in this local Windows project.
- Do not run project training locally.
- Use `remote_test.ps1` for tests after code changes.
- Use `remote_train.ps1` for training.
- Use `remote_run.ps1 -Command "<shell command>"` for remote inspection.
- Keep datasets, checkpoints, logs, outputs, cache, and tmp files on the remote server.
- Treat `reference-project/` as read-only reference material; never import from it or use it as a runtime path.
- Never save passwords. First SSH login may prompt interactively in the terminal.
- After a verified stage, create a Git snapshot with `scripts/create_git_snapshot.ps1`.

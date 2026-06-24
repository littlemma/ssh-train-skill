# Prompt: Git Snapshot Flow

Use small commits as recovery points:

1. Check `git status --short`.
2. Review changed files and confirm no data, weights, checkpoints, logs, outputs, or caches are staged.
3. Run `.\remote_test.ps1`.
4. If tests pass, run:

```powershell
powershell -ExecutionPolicy Bypass -File <skill_dir>\scripts\create_git_snapshot.ps1 -ProjectDir . -Message "stage: concise description"
```

5. If tests fail, fix the failure before committing unless explicitly asked to snapshot a known-broken state.

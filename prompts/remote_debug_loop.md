# Prompt: Remote Debug Loop

Use this loop for failures that occur on the remote Linux server:

1. Reproduce with `.\remote_test.ps1` or `.\remote_run.ps1 -Command "<command>"`.
2. Read the exact remote traceback or log.
3. Identify the smallest local code/config change likely to address the failure.
4. Apply the change locally.
5. Re-run `.\remote_test.ps1`.
6. When passing, create a Git snapshot.

Do not run large training locally. Do not copy remote datasets, checkpoints, logs, outputs, or caches into the local project.

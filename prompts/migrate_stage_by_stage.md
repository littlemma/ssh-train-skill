# Prompt: Stage-by-Stage Migration

Migrate one small subsystem at a time from `reference-project/` into the standard project layout. Before each stage, state the files to read and the target files to edit. After each stage, run `.\remote_test.ps1`. Commit passing stages with `create_git_snapshot.ps1`.

Order:

1. package skeleton and imports;
2. configs and path handling;
3. dataset/data loading;
4. model modules;
5. loss, physics, metrics;
6. trainer/evaluation loop;
7. scripts;
8. smoke tests and docs.

Never use `reference-project/` as a runtime path. Never sync or commit large artifacts. Never save passwords.

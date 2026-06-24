# ssh-train-remote-workflow

Reusable Codex/Superpower Skill for a Windows editing and remote Linux training workflow.

## Reference Summary

The files in `reference/` show the original single-project workflow:

- `README.md`: documents a Windows-local SR_PINN workspace where Codex edits code, while data, checkpoints, logs, outputs, and training live on the server.
- `sync_to_vm.ps1`: uses cwRsync and SSH to sync one hard-coded local directory to one hard-coded remote directory, excluding common runtime artifacts.
- `remote_train.ps1`: syncs first, then SSHs to the server, activates a fixed conda environment, starts a fixed smoke training command with `nohup`, and writes one fixed log file.
- `enable_remote_control.ps1`: modifies local Codex app SQLite settings after making a backup. It is machine-specific and is kept only as reference, not part of the reusable workflow.

This Skill generalizes those ideas into config-driven scripts and templates for new computers, new projects, and new servers.

## New Computer Usage

1. Copy `E:\ssh-train` to the new computer.
2. Copy `examples/project_config.example.json` to `project_config.json`.
3. Edit `project_config.json` for the local project directory, remote host, account, remote directory, conda env, and commands.
4. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\bootstrap_windows.ps1 -ConfigPath .\project_config.json
```

5. Configure SSH key login:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup_ssh_key.ps1 -ConfigPath .\project_config.json
```

Type the remote password only if the terminal prompts for it. The password is never saved.

6. Generate the project workflow:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\init_project_workflow.ps1 -ConfigPath .\project_config.json
```

7. Put the legacy or downloaded reference code into:

```text
<local_project_dir>\reference-project
```

8. Give Codex `prompts/rebuild_from_reference.md` and ask it to rebuild the project into the standard structure.
9. Run remote tests with `<local_project_dir>\remote_test.ps1`.
10. Run training with `<local_project_dir>\remote_train.ps1`.
11. Create small snapshots with:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\create_git_snapshot.ps1 -ProjectDir <local_project_dir> -Message "stage: short description"
```

## Providing Server IP, Account, and Password

Put server IP and account in `project_config.json`:

```json
{
  "remote_host": "192.168.120.215",
  "remote_user": "y24.d01.user17"
}
```

Do not put a password in any file. On first setup, `setup_ssh_key.ps1` runs normal SSH commands, and SSH may prompt in the terminal. Type the password there. After the public key is installed, future commands should be passwordless.

## Rebuilding from Reference Code

Use `prompts/rebuild_from_reference.md` as the instruction template for Codex. The reference code is evidence only:

- scan `reference-project/` first;
- summarize entrypoints, modules, configs, and hard-coded paths;
- migrate in stages into `src/`, `scripts/`, `configs/`, and `tests/`;
- run `remote_test.ps1` after every stage;
- commit each passing stage;
- never run training locally or sync large artifacts.

## Manual Checks

- Confirm `project_config.json` paths match the new computer and server.
- Confirm `rsync.exe` is available from cwRsync or Git Bash.
- Confirm SSH login works without a password after setup.
- Confirm the remote conda environment exists and can run `test_command`.
- Confirm `.syncignore` excludes data, logs, checkpoints, outputs, caches, and model weights.
- Confirm `reference-project/` is never used as the runtime directory.

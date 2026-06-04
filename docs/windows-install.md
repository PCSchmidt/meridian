# Windows Installation

Meridian uses bash hooks and scripts. On Windows you have two good options: **Git
Bash** (easiest, already installed with Git for Windows) or **WSL2** (best
Linux-native experience). Meridian itself is developed on Windows + Git Bash, so
this path is well-tested.

## Option 1 — Git Bash (easiest)

If you have Git for Windows, you already have Git Bash.

1. **Open Git Bash** (not PowerShell or cmd).
2. **Install jq and yq:**
   ```bash
   winget install jqlang.jq
   winget install MikeFarah.yq
   ```
   Reopen Git Bash so the new binaries are on `PATH`. Confirm:
   ```bash
   jq --version && yq --version
   ```
   `yq` must be the **mikefarah** build (the version string contains
   `github.com/mikefarah/yq`), not the Python `yq`.
3. **Install Meridian** into your project:
   ```bash
   bash install.sh /c/Users/you/path/to/project --recipe fullstack-web
   ```
4. **Verify:**
   ```bash
   bash scripts/meridian-doctor.sh   # expect GOOD
   ```

## Option 2 — WSL2 (best performance)

```bash
wsl --install            # in an elevated PowerShell, then reboot
# inside the WSL2 shell:
sudo apt-get update && sudo apt-get install -y jq
sudo wget -qO /usr/local/bin/yq \
  https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
bash install.sh /path/to/project --recipe fullstack-web
```

Work inside the WSL2 filesystem (`~/...`) for best performance; editing across the
`/mnt/c` boundary is slower.

## Line endings (CRLF)

Git on Windows often converts `LF → CRLF` on checkout. You'll see warnings like
`LF will be replaced by CRLF` when staging — these are **harmless**; the working
file keeps its original endings. Bash scripts run fine with either.

If a hook ever fails with a `\r`-related error, normalize endings for shell files
by adding a `.gitattributes`:

```gitattributes
*.sh   text eol=lf
*.bash text eol=lf
```

Then re-checkout (`git rm --cached -r . && git reset --hard`). Meridian's scripts
are written to tolerate CRLF where it matters (memory parsing strips `\r`), but
keeping `*.sh` as LF avoids surprises.

## bash version

Meridian needs **bash ≥ 4** (the gate engine uses associative arrays). Git for
Windows ships bash 4.4+, so Git Bash is fine. `meridian-doctor.sh` checks this and
flags an old bash as CRITICAL.

## PATH and the Bash tool

If `meridian-doctor.sh` reports `yq` missing even after install, the binary isn't
on the `PATH` of the shell running the hook. winget installs to
`~/AppData/Local/Microsoft/WinGet/Links`, which Git Bash includes — reopen the
shell after installing. In editors that spawn their own terminal, restart the
editor so it picks up the updated `PATH`.

## Common Windows issues

See [troubleshooting.md](troubleshooting.md) — the `yq`-missing,
PATH, and CRLF cases are covered there with fixes.

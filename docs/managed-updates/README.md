# Managed service updates

AI CoreKit managed updates are opt-in and Git-native. A service must declare an enabled `managed_update` policy in its `service.json`; missing policy means disabled. n8n is the only initially enabled service.

Renovate proposes grouped, digest-pinned n8n application and runner changes. CI builds both exact images, rejects candidates that are not the official stable n8n GitHub release, starts an isolated PostgreSQL/n8n/runner bundle, and executes a no-side-effect manual canary. The host deployer installs only a clean committed candidate from the configured deployment branch. It never selects a moving registry tag.

## Commands

```bash
corekit managed-update check n8n
corekit managed-update plan n8n
corekit managed-update apply n8n --dry-run
corekit managed-update apply n8n
corekit managed-update status n8n
corekit managed-update rollback-plan n8n
```

`check` uses `git ls-remote` and does not update refs or the worktree. Normal `apply` fetches only the configured branch, requires a clean tree and expected branch, and permits only a fast-forward. Patch/minor candidates need seven days of soak; major candidates need `--manual-major`. A verified urgent security update may use `--security-override`, but it still builds first, checks space and executions, creates a complete recovery set, passes a restore drill, and passes every live readiness/canary/count/audit gate.

Manual commands default to the current account's XDG directories: managed state under `$XDG_STATE_HOME` (or `$HOME/.local/state`) and recovery sets under `$XDG_DATA_HOME` (or `$HOME/.local/share`). Set `COREKIT_MANAGED_STATE_ROOT` and `COREKIT_N8N_BACKUP_ROOT` to use operator-selected protected locations. The updater preserves verified recovery sets and never deletes backups automatically; the policy's retention value is a protection floor, not a deletion threshold. Stateful database restoration is never automatic: a failed candidate is stopped and marked as possibly having accepted writes.

## Scheduling

The systemd installer renders the committed templates for a selected unprivileged account with `UMask=0077`, journald logs, timeouts, and `flock`. It uses `--user` when supplied; otherwise it detects the non-root sudo caller or non-root checkout owner. It never silently schedules updates as root.

- daily check: 03:15 UTC, randomized up to 30 minutes;
- weekly apply: Sunday 04:15 UTC, randomized up to 20 minutes.

The apply timer runs only the Git deployer. It does not run the broad `corekit update`, query a registry for a newest tag, or use Watchtower.

Install or refresh the root-owned units with:

```bash
sudo ./scripts/install-managed-update-systemd.sh
```

Use `--project-root`, `--state-root`, and `--backup-root` when the detected defaults are not appropriate. The selected account needs access to the checkout, the Docker daemon used by CoreKit, and the protected state/recovery directories. A dedicated service account is recommended, but no account name or home-directory layout is required.

If the Renovate GitHub App is not installed, install it for the repository at <https://github.com/apps/renovate> and allow it to open pull requests. The committed configuration is `renovate.json`.

Renovate opens grouped, reviewable PRs, but automerge remains disabled until the repository enforces the `validate` and `candidate` status checks on its deployment branch. Do not enable platform automerge without those required checks; existing CI is not equivalent to GitHub enforcing it before merge.

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

Runtime state is protected at `/home/services/.local/state/ai-corekit/managed-updates/`. Recovery sets are protected at `/home/services/backups/ai-corekit/n8n/`. The updater preserves verified recovery sets and never deletes backups automatically; the policy's retention value is a protection floor, not a deletion threshold. Stateful database restoration is never automatic: a failed candidate is stopped and marked as possibly having accepted writes.

## Scheduling

The committed systemd units run as `services` with `UMask=0077`, journald logs, timeouts, and `flock`:

- daily check: 03:15 UTC, randomized up to 30 minutes;
- weekly apply: Sunday 04:15 UTC, randomized up to 20 minutes.

The apply timer runs only the Git deployer. It does not run the broad `corekit update`, query a registry for a newest tag, or use Watchtower.

Install or refresh the root-owned units with:

```bash
sudo /home/services/ai-launchkit/scripts/install-managed-update-systemd.sh
```

If the Renovate GitHub App is not installed, install it for `tcoretech/ai-corekit` at <https://github.com/apps/renovate> and allow it to open pull requests. The committed configuration is `renovate.json`.

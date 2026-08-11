# n8n managed-update baseline

The committed n8n application and runner images use the same explicit version
and immutable registry digests. CI builds both images, verifies the application
version, and rejects a candidate that is not the current official stable n8n
release. Urgent security updates may bypass only the release-age gate; build,
backup, restore, migration, readiness, canary, and audit gates remain mandatory.

The current version floor includes the fix for CVE-2026-25049
(`GHSA-6cqr-8cfr-67f8`), which was fixed in n8n `2.5.2`. Version and digest
changes belong in a grouped Renovate pull request rather than an operator's
local configuration.

## Default topology

The reusable Compose bundle defaults to standard execution mode with one n8n
process and one matching external runner. It does not provision n8n queue
workers. Queue-mode operators must separately provide and validate the required
licensing, Redis, supported binary storage, scaling design, and an exact-version
runner for every execution process.

This baseline describes repository defaults, not the inventory, scale, data,
licensing, workflows, or execution history of any particular deployment. Keep
environment assessments and upgrade evidence in access-controlled operational
records rather than committing them to this public runbook.

## Compatibility and least privilege

`n8n-git` is pinned by release version and commit; its installer and source
archive are checksummed, and CI exercises an encrypted-by-default dry-run export
against the candidate.

The runner is unprivileged, read-only, capability-free, has no Docker socket,
and receives only its broker token and operational settings. Treat any new
runner dependency or module allowlist entry as a separate pinned, tested change.

## Authoritative references

- <https://github.com/n8n-io/n8n/security/advisories/GHSA-6cqr-8cfr-67f8>
- <https://docs.n8n.io/hosting/configuration/task-runners/>
- <https://docs.n8n.io/hosting/scaling/external-storage/>
- <https://docs.n8n.io/hosting/scaling/queue-mode/>

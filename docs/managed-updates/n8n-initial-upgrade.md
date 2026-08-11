# Initial managed n8n upgrade decision

Assessment date: 2026-08-11 UTC.

The initial managed target is n8n `2.34.4`. The official `stable` tag was
promoted to that release on 2026-08-11. The exact application and runner image
indexes are committed by digest and CI rejects a version that is not the
current official stable release. The release-age gate is bypassed only for this
manual security upgrade; build, backup, restore, migration, readiness, canary,
and audit gates remain mandatory.

The old `2.2.4` application is within the affected range of CVE-2026-25049
(`GHSA-6cqr-8cfr-67f8`), which is fixed from `2.5.2`. The selected target also
includes subsequent fixes, including task-runner health and recovery fixes.

## Topology decision

Production uses standard execution mode with one n8n process and one matching
external runner. Queue workers and n8n's Redis dependency are removed. Redis
remains available to other CoreKit services and is not restarted or changed.

This decision follows the observed deployment facts:

- no active or waiting executions and no active workflows;
- 319 stored workflow templates, four credentials, and no execution history;
- no n8n Enterprise licence or supported external binary-storage configuration
  was discoverable;
- the filesystem binary-data volume contained only a few kilobytes; and
- the workload did not demonstrate a scaling need for two queue workers.

Queue mode with filesystem binary storage is unsupported, while n8n external
storage is an Enterprise feature. A future queue-mode proposal must provide the
licence/storage design and an exact-version runner for every execution process.

## Compatibility and least privilege

The custom application image retains the media tools and exact Python packages
present in the old build. `n8n-git` is installed as `v1.2.3` from release commit
`5916cfed2561016afdc34c3f31d6ab13f59394eb`; its installer and source archive
are checksummed, and CI exercises an actual encrypted-by-default dry-run export
against the candidate.

The runner is unprivileged, read-only, capability-free, has no Docker socket,
and receives only its broker token and operational settings. The current
production-compatible allowlist grants only the built-in `crypto` and `util`
modules. Some inactive templates reference `xlsx`; it was already unavailable
to the old external runner and the npm
package is not added implicitly. Any activation of those templates requires a
separate review and a pinned, tested runner dependency.

## Authoritative references

- <https://github.com/n8n-io/n8n/releases/tag/n8n%402.34.4>
- <https://github.com/n8n-io/n8n/security/advisories/GHSA-6cqr-8cfr-67f8>
- <https://docs.n8n.io/hosting/configuration/task-runners/>
- <https://docs.n8n.io/hosting/scaling/external-storage/>
- <https://docs.n8n.io/hosting/scaling/queue-mode/>

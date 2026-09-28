# Managed updates

`corekit managed-update` deploys a committed, tested version of a service. It is
service-agnostic: everything it knows about a particular service comes from that
service's own directory.

## Registering a service

A service is registered by a `managed_update` block in its `service.json`:

```json
"managed_update": {
  "enabled": true,
  "deployment_branch": "main",
  "channel": "stable",
  "minimum_release_age_days": 7,
  "automatic_update_types": ["patch", "minor"],
  "major_updates_require_manual_approval": true,
  "backup_required": true,
  "minimum_free_space_gb": 15,
  "components": ["service", "service-worker"]
}
```

`enabled: false`, or no block at all, means the service is never touched. List
what is registered with:

```bash
corekit managed-update list
```

## Hooks

Anything service-specific lives in `<service>/managed/`. The driver runs these
and treats a non-zero exit as a failed deployment. Every hook is optional except
where noted; a missing hook means that step is skipped.

| Hook | Required | Purpose | Contract |
|---|---|---|---|
| `version.sh` | yes | What version is committed, and what is live | Prints one JSON object: `{"target_version","live_version","identity"}`. `identity` is any string that changes when the committed build would change |
| `validate.sh` | no | Refuse an incoherent committed bundle | Exit non-zero to abort. Message on stderr |
| `build.sh` | no | Build or pull the candidate and verify it is what was asked for | Receives the target version as `$1`. Prints JSON `{"images":{...}}` on the last line |
| `backup.sh` | when `backup_required` | Create and verify a recovery set | Prints the manifest path on the last line. The manifest must report `verified: true` |
| `counts.sh` | no | Entity counts and in-flight executions | Prints `{"workflows","credentials","active_executions"}`. Without it, count gating is skipped |
| `deploy.sh` | yes | Recreate the service with the candidate | Receives the target version as `$1`, and the candidate images as `COREKIT_CANDIDATE_IMAGES` |
| `strict-healthcheck.sh` | yes | Readiness, counts, canary | Exit non-zero if the deployment should be treated as failed |

Hooks run with `COREKIT_PROJECT_ROOT`, `COREKIT_SERVICE_DIR` and
`COREKIT_SERVICE_NAME` in the environment.

`counts.sh` matters more than it looks. A service with its own database must
report from that database: measuring one instance against another instance's
numbers would let a deployment that silently lost data pass its checks.

## Why hooks rather than configuration

Services differ in ways configuration cannot express. One builds an image from a
Dockerfile; another adopts an image another service already built. One holds its
data in a shared database; another in its own. A hook is a small script in the
service's own directory, next to the Compose file it belongs to, which is where
someone changing that service will look.

## Gates

Ordered, each stopping the run:

1. The service is registered and enabled
2. The worktree is clean and on the deployment branch
3. The committed bundle validates
4. The change is not a downgrade, and a major change has explicit approval
5. The release-age gate is met, or is explicitly overridden
6. Free space is above the floor
7. The candidate builds and verifies
8. A recovery set is created and verified
9. The deployment succeeds
10. Strict health passes

Only then is the run recorded as successful. A deployment that leaves the
service unhealthy is a failed deployment whatever the build reported.

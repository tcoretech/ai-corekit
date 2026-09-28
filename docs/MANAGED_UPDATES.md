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
  "components": ["service", "service-runner"]
}
```

`enabled: false`, or no block at all, means the service is never touched. List
what is registered with:

```bash
corekit managed-update list
```

## Hooks

Anything service-specific lives in `<service>/managed/`. The driver runs these
and treats a non-zero exit as a failed deployment. Three are optional and are
skipped when absent: `validate.sh`, `counts.sh` and `stop.sh`. The rest are
called unconditionally, and a missing one fails the run.

| Hook | Required | Purpose | Contract |
|---|---|---|---|
| `version.sh` | yes | What version is committed, and what is live | Prints one JSON object: `{"target_version","live_version","identity"}`. `identity` is any string that changes when the committed build would change |
| `validate.sh` | no | Refuse an incoherent committed bundle | Exit non-zero to abort. Message on stderr |
| `build.sh` | yes | Build or pull the candidate and verify it is what was asked for | Receives the target version as `$1`. Prints JSON `{"images":{...}}` on the last line. A service that builds nothing still needs one, to verify the image it adopts |
| `backup.sh` | yes | Create and verify a recovery set | Prints the manifest path on the last line. The manifest must report `verified: true`, `restore_drill.result: "passed"` and `candidate_migration_drill.result: "passed"` — see below |
| `counts.sh` | in practice yes | Entity counts and in-flight executions | Prints `{"workflows","credentials","active_executions"}`. Must exit non-zero if it cannot read them: reporting zero would let a deployment proceed during a database outage. Without the hook, the post-deployment count check fails the deployment |
| `stop.sh` | no | Stop this service's containers after a failed health check | Without it the driver stops the containers named in `components` |
| `deploy.sh` | yes | Recreate the service with the candidate | Receives the target version as `$1`, and the candidate images as `COREKIT_CANDIDATE_IMAGES` |
| `strict-healthcheck.sh` | yes | Readiness, counts, canary | Exit non-zero if the deployment should be treated as failed |

Hooks run with `COREKIT_PROJECT_ROOT`, `COREKIT_SERVICE_DIR` and
`COREKIT_SERVICE_NAME` in the environment. `backup.sh` also receives
`COREKIT_MANAGED_BACKUP_ROOT`, and `deploy.sh` receives
`COREKIT_CANDIDATE_IMAGES`, the JSON that `build.sh` printed.

`components` is ordered and load-bearing: the first entry is the container whose
image is recorded as the rollback target, the second is its task runner. Recovery
hands both to the operator, so listing them the other way round would tell them
to restart the wrong image.

### The backup manifest

The driver refuses to deploy unless the manifest reports all three of:

```json
{ "verified": true,
  "restore_drill":            { "result": "passed" },
  "candidate_migration_drill":{ "result": "passed" } }
```

`verified` is an assertion the hook makes about itself, so it is worth no more
than the work behind it. A hook that writes `verified: true` without restoring
anything turns the gate into decoration. Restore the dump somewhere isolated and
compare what comes back against the live instance before claiming it.

Where a step does not apply — a service that adopts a prebuilt image has no
candidate whose migrations need rehearsing — say so explicitly in the manifest
with a `note`, rather than omitting the key. An absent key fails the gate, which
is correct: silence should not pass.

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

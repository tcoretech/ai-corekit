# Promotion

Imports workflow definitions into an n8n service from a commit that is already
merged into a protected branch.

It is exposed on the service rather than as a top-level corekit verb, because it
is n8n-specific: it drives `n8n-git` and the n8n CLI inside the container, and
nothing else in the catalogue could use it as written.

    corekit run <service> promote [options]

## The problem it solves

A service where definitions can be authored freely is a poor place to keep
production credentials: anything that can write a definition and run it can use
those credentials, without ever reading the secret itself. A service that holds
production credentials is therefore a poor place to author freely.

Splitting authoring from production is the usual answer, and it leaves one gap:
how a change crosses from one to the other. Get that crossing wrong and it
becomes the very thing the split was meant to prevent — a way to run an
arbitrary definition against real credentials.

## The shape

```
authoring instance  --push-->  branch  --review, merge-->  protected branch
                                                                  |
                                                    corekit run <svc> promote (host)
                                                                  v
                                                          production instance
```

Four properties make the crossing safe:

| Property | How |
|---|---|
| The artefact is fixed | A full 40-character commit SHA. A branch tip moves; a commit does not |
| It has been reviewed | The commit must be an ancestor of the protected branch. Whatever review that branch requires has therefore happened |
| It is recoverable | The target is exported before the import, and the run is recorded with the previous commit |
| It cannot be self-triggered | It is a host command. Nothing running inside either instance can invoke it |

That last one matters most. An approval step that the authoring instance can
trigger is not a control — it becomes a prompt that gets waved through. Keep the
decision on the host, with a human.

## Credentials are never imported

`--credentials 0` is passed unconditionally. Credentials are created once, by
hand, on the production instance. Two consequences worth stating:

- A promoted definition can only use credentials that already exist there, so
  promotion cannot introduce new reach.
- Definitions exported from another instance are encrypted with *that*
  instance's key and are inert anywhere else. Never export decrypted
  credentials to work around this; that would defeat the entire arrangement.

## Configuration

Split by whether it is safe to publish.

**`service.json`** — policy, committed:

```json
"promotion": {
  "enabled": true,
  "protected_branch": "main",
  "repository_path": "workflows",
  "preserve_ids": true,
  "backup_required": true,
  "credentials": "never"
}
```

**The service `.env`** — site-specific, not tracked:

```
PROMOTION_REPOSITORY='owner/repo'
PROMOTION_TOKEN='...'
# Optional; these override the policy in service.json.
# No inline comments: the value is read literally, so a trailing comment
# would become part of the branch name or path.
PROMOTION_BRANCH='main'
PROMOTION_PATH='workflows'
```

Give the token **read access only**. The control is the branch protection on the
repository, not the secrecy of this token: a read-only token cannot promote
anything that has not been merged, so leaking it costs you nothing that matters.

This is the right way round deliberately. If the authoring instance can run
shell commands or read files — and most can — then any token it can reach is
one an injected instruction can steal. Design so that stealing it is not worth
anything.

## Use

```bash
corekit run <service> promote --plan             # show what would happen
corekit run <service> promote                    # promote the protected branch tip
corekit run <service> promote --commit <sha>     # promote one exact commit
corekit run <service> promote --dry-run          # import in the tool's dry-run mode
corekit run <service> status                     # what is deployed, and from where
corekit run <service> rollback-plan              # recovery procedure
```

A service opts in by shipping a `cli.sh` that delegates to the shared
implementation in `the service's managed/promote.sh`, and a `promotion` block in its
`service.json`.

`--plan` changes nothing and needs no lock, so it is safe to run at any time.

## A note on `counts.sh`

Promotion reads the target's workflow count through the service's `counts.sh`
hook, to tell a genuinely empty target — where the first promotion happens and
an empty recovery set is expected — from one whose count cannot be read, where a
backup matters most. Without that hook the count is unknown, so the first
promotion into an empty target is refused. That is the safe default rather than a
fault, but it is worth knowing before adding promotion to a service that has no
counts hook.

## Gates

A promotion stops at the first failure:

1. Promotion is enabled for the service in `service.json`
2. `PROMOTION_REPOSITORY` and `PROMOTION_TOKEN` are set
3. The target container exists and is running
4. The commit resolves, and is a full SHA if given explicitly
5. **The commit is an ancestor of the protected branch** — enforced by the
   import tool, not by this script
6. A pre-promotion export succeeds and is non-empty
7. The import succeeds
8. The container is healthy afterwards

Only then is the run recorded. A promotion that leaves the service unhealthy is
a failed promotion, whatever the import reported.

## Recovery

`corekit run <service> rollback-plan` prints the procedure and the recorded
previous commit. Rolling forward to the previous commit is usually right and is
the same deterministic path. Restoring the pre-promotion export is for when the
definitions are not the problem.

Restoring is refused automatically, by design: if the service may have accepted
writes since the promotion, an automatic restore would destroy them. Establish
that first.

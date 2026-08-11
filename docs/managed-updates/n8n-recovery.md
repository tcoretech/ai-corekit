# n8n guarded recovery

Never overwrite the production database merely because a new container is unhealthy. First run `corekit managed-update rollback-plan n8n`, preserve failed-container logs, and establish whether any workflow, credential, execution, user, webhook, or setting changed after cutover.

If post-upgrade writes might exist, leave n8n stopped, preserve the current database and recovery set, and escalate. Do not load the old image against a migrated database and do not restore the pre-upgrade dump.

Only after writes are conclusively ruled out:

1. Verify the recovery-set `manifest.json` says `verified: true` and restore drill `passed`.
2. In the recovery-set directory, run `sha256sum -c checksums.sha256`.
3. Load the durable images with `gzip -dc previous-images.tar.gz | docker image load`.
4. Repeat a network-isolated restore drill of `postgres.dump` and verify the recorded workflow/credential counts.
5. Stop only `n8n` and `n8n-runner`. Take a second dump of the failed database as evidence.
6. During an approved maintenance window, restore `postgres.dump` to the actual n8n database using the PostgreSQL image recorded in `manifest.json`. Database recreation is intentionally a manual, destructive action and is not scripted by the updater.
7. Restore `n8n-volume.tar.gz` to the recorded n8n volume if the failed deployment changed that volume.
8. Start the rollback tags recorded in the recovery image archive and the previous Compose configuration archive.
9. Run strict `/healthz`, `/healthz/readiness`, PostgreSQL, runner, migration-log, entity-count, canary, and security-audit checks before reopening service.

The protected `n8n-encryption-key.protected` decrypts both the AES-encrypted exports and n8n credentials. For example, decrypt an export only inside a protected recovery workspace:

```bash
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 \
  -pass file:n8n-encryption-key.protected \
  -in credentials.json.enc -out credentials.json
```

Delete any decrypted recovery copy after validation. Never commit or print it.

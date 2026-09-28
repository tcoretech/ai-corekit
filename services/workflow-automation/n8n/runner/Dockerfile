# syntax=docker/dockerfile:1.7

# renovate: datasource=docker depName=n8nio/runners
FROM n8nio/runners:2.39.6@sha256:b6d97c54f9ee6e2227351b551f92e457e17891ab622d038277dd0c70a3f28cca

LABEL io.corekit.managed-service="n8n" \
      io.corekit.runner-for-n8n-version="2.39.6"

# The upstream image already runs as the unprivileged UID/GID 1000 runner.
# Extra packages remain absent until an active production workflow demonstrates
# a need and a separately reviewed, pinned runner build is added.
USER runner

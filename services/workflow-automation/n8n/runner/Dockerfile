# syntax=docker/dockerfile:1.27@sha256:bde3983e9c939224420ddaf6b784cc30e09b035a4dea01f581230c50809f372e

# renovate: datasource=docker depName=n8nio/runners
FROM n8nio/runners:2.34.4@sha256:908096845a12c8e3a9214b8f93d72b745036607fe67cda06b4b2bab0f43e0777

LABEL io.corekit.managed-service="n8n" \
      io.corekit.runner-for-n8n-version="2.34.4"

# The upstream image already runs as the unprivileged UID/GID 1000 runner.
# Extra packages remain absent until an active production workflow demonstrates
# a need and a separately reviewed, pinned runner build is added.
USER runner

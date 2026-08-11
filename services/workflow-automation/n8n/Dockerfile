# syntax=docker/dockerfile:1.7

# renovate: datasource=docker depName=alpine
FROM alpine:3.24@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b AS apk-builder
RUN apk add --no-cache apk-tools-static=3.0.7-r0

# Keep the readable version and immutable digest together. CI verifies this
# version matches the runner image and the managed-update policy.
# renovate: datasource=docker depName=n8nio/n8n
FROM n8nio/n8n:2.34.4@sha256:f69bad7a699300702af665b9f13fc67455b93c9fb9174bca6c37f3d4a47b8583

ARG N8N_GIT_VERSION=v1.2.3
ARG N8N_GIT_COMMIT=5916cfed2561016afdc34c3f31d6ab13f59394eb
ARG N8N_GIT_INSTALL_SHA256=177fbe5a8740db1014c68833f049444a49780424b33142a688e3a80ba0ad358d
ARG N8N_GIT_ARCHIVE_SHA256=9646d11d9667cde9b3fac9d03403059b0c339f73e233c9cb135199592ff27601

LABEL io.corekit.managed-service="n8n" \
      io.corekit.n8n-git.version="${N8N_GIT_VERSION}" \
      io.corekit.n8n-git.commit="${N8N_GIT_COMMIT}"

USER root

# n8n's hardened Alpine base intentionally omits apk itself. Bootstrap the
# package manager from an immutable matching Alpine image, then install exact
# top-level package versions. No secret is accepted as a build argument.
COPY --from=apk-builder /sbin/apk.static /usr/local/bin/apk.static
RUN /usr/local/bin/apk.static add --no-cache --upgrade \
      libapk=3.0.7-r0 apk-tools=3.0.7-r0 && \
    rm /usr/local/bin/apk.static && \
    apk add --no-cache \
      bash=5.3.9-r1 \
      curl=8.21.0-r0 \
      exiftool=13.55-r0 \
      ffmpeg=8.1.2-r0 \
      ghostscript=10.07.1-r0 \
      imagemagick=7.1.2.27-r0 \
      jq=1.8.1-r0 \
      mediainfo=26.01-r0 \
      py3-pip=26.1.2-r0 \
      python3=3.14.5-r0 \
      sox=14.4.2-r14

# Fetch both the installer and its source archive from the immutable release
# commit, verify both before execution, and install without consulting main or
# a moving "latest" release pointer.
RUN curl -fsSL --retry 3 \
      "https://raw.githubusercontent.com/tcoretech/n8n-git/${N8N_GIT_COMMIT}/install.sh" \
      -o /tmp/n8n-git-install.sh && \
    curl -fsSL --retry 3 \
      "https://github.com/tcoretech/n8n-git/archive/${N8N_GIT_COMMIT}.tar.gz" \
      -o /tmp/n8n-git.tar.gz && \
    echo "${N8N_GIT_INSTALL_SHA256}  /tmp/n8n-git-install.sh" | sha256sum -c - && \
    echo "${N8N_GIT_ARCHIVE_SHA256}  /tmp/n8n-git.tar.gz" | sha256sum -c - && \
    VERSION="${N8N_GIT_VERSION}" \
      N8N_GIT_SOURCE_REF="${N8N_GIT_COMMIT}" \
      N8N_GIT_SOURCE_URL="file:///tmp/n8n-git.tar.gz" \
      bash /tmp/n8n-git-install.sh && \
    grep -Fqx "VERSION=\"${N8N_GIT_VERSION#v}\"" /usr/local/bin/n8n-git && \
    rm /tmp/n8n-git-install.sh /tmp/n8n-git.tar.gz

RUN pip3 install --no-cache-dir --break-system-packages \
      audioop-lts==0.2.2 \
      Pillow==12.1.0 \
      pydub==0.25.1 && \
    python3 -c 'import PIL, pydub' && \
    rm -rf /root/.cache

RUN install -d -o 1000 -g 1000 -m 0775 /data/media /data/temp

USER node
WORKDIR /data

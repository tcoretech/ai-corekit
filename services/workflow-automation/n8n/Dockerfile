FROM alpine:3.23 AS builder
RUN apk add --no-cache apk-tools-static

FROM n8nio/n8n:latest
USER root

# Copy the static apk binary
COPY --from=builder /sbin/apk.static /usr/local/bin/apk.static

# Reinstall apk-tools using the static binary
RUN /usr/local/bin/apk.static add --no-cache apk-tools && \
    rm /usr/local/bin/apk.static

# Install ffmpeg and enhanced media processing tools
RUN apk update && apk add --no-cache \
    ffmpeg \
    imagemagick \
    exiftool \
    mediainfo \
    sox \
    ghostscript \
    python3 \
    py3-pip \
    git \
    curl \
    bash \
    openssh-client \
    && rm -rf /var/cache/apk/*

# Install n8n-git:
ARG N8N_GIT_VERSION=latest
RUN curl -fsSL https://raw.githubusercontent.com/tcoretech/n8n-git/main/install.sh | \
    VERSION="${N8N_GIT_VERSION}" bash

# Install Python libraries for advanced media processing
RUN pip3 install --no-cache-dir --break-system-packages \
    pydub \
    Pillow \
    && rm -rf /root/.cache

# Create media directories with proper permissions for node user
# UID 1000 is the node user in the n8n container
RUN mkdir -p /data/media /data/temp && \
    chown -R 1000:1000 /data/media /data/temp && \
    chmod 775 /data/media /data/temp

USER node
WORKDIR /data

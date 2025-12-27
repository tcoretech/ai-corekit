FROM alpine:3.23 AS builder

FROM n8nio/n8n:latest
USER root

# Restore apk from builder
COPY --from=builder /sbin/apk /sbin/apk
COPY --from=builder /lib/apk /lib/apk
COPY --from=builder /etc/apk /etc/apk
COPY --from=builder /usr/share/apk /usr/share/apk
COPY --from=builder /usr/lib/libapk.so.3.0.0 /usr/lib/libapk.so.3.0.0
COPY --from=builder /usr/lib/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=builder /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3

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

# Install n8n-git for automated n8n backups
RUN curl -fsSL https://raw.githubusercontent.com/tcoretech/n8n-git/main/install.sh | bash

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

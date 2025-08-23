FROM n8nio/n8n:latest
USER root

# Install ffmpeg and enhanced media processing tools
RUN apk add --no-cache \
    ffmpeg \
    imagemagick \
    exiftool \
    mediainfo \
    sox \
    ghostscript \
    python3 \
    py3-pip \
    && rm -rf /var/cache/apk/*

# Install Python libraries for advanced media processing
RUN pip3 install --no-cache-dir --break-system-packages \
    pydub \
    Pillow \
    && rm -rf /root/.cache

# Create media directories for processing
RUN mkdir -p /data/media /data/temp && \
    chown -R node:node /data/media /data/temp

USER node

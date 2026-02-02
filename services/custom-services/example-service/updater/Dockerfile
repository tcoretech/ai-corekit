FROM docker:cli

RUN apk add --no-cache git bash curl

# Install Docker Compose plugin
RUN mkdir -p /usr/local/lib/docker/cli-plugins && \
    curl -SL https://github.com/docker/compose/releases/download/v2.32.1/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose && \
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

WORKDIR /app

COPY start.sh /app/start.sh
COPY templates /app/templates
RUN chmod +x /app/start.sh

ENTRYPOINT ["/app/start.sh"]

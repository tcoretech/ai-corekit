FROM node:20-slim
WORKDIR /app

# Install git and required libraries
RUN apt-get update && apt-get install -y \
    git \
    libatomic1 \
    && rm -rf /var/lib/apt/lists/*

# Clone bolt.diy repository
RUN git clone -b stable --depth 1 https://github.com/stackblitz-labs/bolt.diy.git .

# Install pnpm and dependencies
RUN npm install -g pnpm@9.15.9
RUN pnpm install --frozen-lockfile

# Copy our startup script (patches at runtime)
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Use existing node user for security
RUN chown -R node:node /app
USER node

EXPOSE 5173
CMD ["/app/start.sh"]

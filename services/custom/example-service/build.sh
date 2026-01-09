#!/bin/bash
# Build the updater image explicitly with no cache and pull base image
docker compose build --no-cache --pull

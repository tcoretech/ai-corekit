#!/bin/bash
# Create the data directories with the ownership each image needs, before the
# containers start. n8n runs as uid 1000; the postgres image chowns its own
# PGDATA on first run.
set -e
install -d -m 700 ./data
install -d -o 1000 -g 1000 -m 700 ./data/n8n
install -d -m 700 ./data/db

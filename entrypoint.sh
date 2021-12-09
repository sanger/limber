#!/bin/bash

# Note that this file is for the exclusive use of the Dockerfile as an ENTRYPOINT
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

# Generate the latest config on launch
bundle exec rails config:generate

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"

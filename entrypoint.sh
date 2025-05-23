#!/bin/bash

# Note that this file is for the exclusive use of the Dockerfile as an ENTRYPOINT
set -e

echo "Running container entrypoint script"

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

# Install any missing packages - very useful for development without rebuilding the image
BUNDLE_IGNORE_FUNDING_REQUESTS=FALSE bundle install

# Generate the latest config on launch
if [ "${GENERATE_CONFIG:-}" = "true" ]; then
  bundle exec rails config:generate
fi

# Build the static web assets
if [ "${PRECOMPILE_ASSETS:-}" = "true" ]; then
  bundle exec rails assets:precompile
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"

#!/bin/bash

# Note that this file is for the exclusive use of the Dockerfile as an ENTRYPOINT
set -e

# Support generating the config on launch
if [ "${GENERATE_CONFIG:-}" = "true" ]; then
  echo "Generating config using Sequencescape"
  bundle exec rails config:generate
fi

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"

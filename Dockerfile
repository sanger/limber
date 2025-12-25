FROM ruby:3.4.8-slim

# Major version of Node.js to install
ARG nodeVersion=22

ARG bundlerWithout="development test lint"
ARG yarnFlags="--production"

# Install required software:
#  - build-essential: to have a compiling environment for building gems
#  - curl: for setting Node version and healthcheck
#  - git is a rails gems dependency
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y curl
RUN apt-get install -y git

RUN set -uex \
    && NODE_MAJOR=${nodeVersion} \
    && apt-get update \
    && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
    | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" \
    | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install nodejs -y;

# Install Python for deasync [node-gyp]
# Issue: https://github.com/abbr/deasync/issues/106
# Resolution: https://github.com/nodejs/node-gyp?tab=readme-ov-file#installation
RUN apt-get install -y python3

# Change the working directory for all proceeding operations
#   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#workdir
WORKDIR /code

# Install build tools
RUN npm install --global yarn
RUN gem install bundler

# Install bundler based dependencies
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle config set without "${bundlerWithout}"
RUN bundle install

# Install yarn based dependencies
COPY package.json .
COPY yarn.lock .
RUN rm -rf node_modules && yarn install --frozen-lockfile ${yarnFlags}

# "items (files, directories) that do not require ADD’s tar auto-extraction capability, you should always use COPY."
#   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy
COPY . .

# Set up ENTRYPOINT script as a system binary
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# "The best use for ENTRYPOINT is to set the image’s main command, allowing that image to be run as though it was that
#   command (and then use CMD as the default flags)."
#   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3001"]

# https://docs.docker.com/engine/reference/builder/#healthcheck
HEALTHCHECK --interval=30s --timeout=10s  --retries=4 \
    CMD curl -f http://localhost:3001/health || exit 1

FROM ruby:2.7.5-slim

# Install required software:
#  - build-essential: to have a compiling environment for building gems
#  - curl: for setting Node version and healthcheck
#  - git is a rails gems dependency
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y curl
RUN apt-get install -y git

# Set Node to install version 14
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update
RUN apt-get install -y nodejs

# Change the working directory for all proceeding operations
#   https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#workdir
WORKDIR /code

# Install build tools
RUN npm install --global yarn
RUN gem install bundler

# Install bundler based dependencies
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install

# Install yarn based dependencies
COPY package.json .
COPY yarn.lock .
RUN rm -rf node_modules && yarn install --frozen-lockfile

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
CMD ["bundle", "exec", "rails", "server"]

# https://docs.docker.com/engine/reference/builder/#healthcheck
HEALTHCHECK --interval=30s --timeout=10s  --retries=4 \
    CMD curl -f http://localhost:3001/health || exit 1

ARG CHIPSET=default

# Use the correct base image depending on the architecture
# For Apple M1 Chip, run: docker build --build-arg CHIPSET=m1
FROM ruby:2.7.8-slim AS base_default
FROM --platform=linux/amd64 ruby:2.7.8-slim AS base_m1
FROM base_${CHIPSET} AS base


# Install required software:
#  - net-tools: to run ping and other networking tools
#  - build-essential: to have a compiling environment for building gems
#  - curl: for healthcheck
#  - yarn and git are rails gems dependencies
RUN apt-get update && apt-get install -y \
build-essential \
curl \
git \
net-tools \
nodejs \
npm \
vim \
wget \
yarn

WORKDIR /code

COPY Gemfile /code
COPY Gemfile.lock /code

ADD . /code/

# Rails installation
RUN npm install --global yarn
RUN gem install bundler
RUN bundle install
RUN yarn --install

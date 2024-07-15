# Limber Pipeline Application

![Linting](https://github.com/sanger/limber/workflows/Linting/badge.svg)
![Ruby RSpec Tests](https://github.com/sanger/limber/workflows/Ruby%20RSpec%20Tests/badge.svg)
![Javascript testing](https://github.com/sanger/limber/workflows/Javascript%20testing/badge.svg)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/limber)

## Description

A flexible front end to plate bases pipelines in Sequencescape.

## Initial Setup (using Docker)

Docker provides all the dependencies needed by Limber, so there is less to
install on your machine. It can make development harder though, so it might be
preferable to use a native installation (see below) if that is possible on your
machine. The only dependency that isn't provided is Sequencescape, so please
ensure you have that running on port 3000 on your localhost before attempting to
run Limber in Docker.

You must have Docker Desktop installed on your machine. Then the only command
you should need to run is:

```shell
docker-compose up
```

Variations on this command include:

- `docker-compose up -d` which starts the container as a background task
  (freeing up the terminal). You can then use `docker-compose down` to turn it
  off again.
- `GENERATE_CONFIG=false docker-compose up` which will avoid running the
  `config:generate` rake task as Limber is started.
- `docker-compose up --build` which forces a rebuild of the Docker image if your
  changes to the Dockerfile or related scripts don't seem to be taking effect.

Limber should be accessible via [http://localhost:3001](http://localhost:3001).

## Initial Setup (using native installation)

Because Limber is only a frontend that relies on SequenceScape as a backend, SequenceScape and it's jobs **must** be started first. SequenceScape **will** work standalone without Limber, Limber **won't** run without SequenceScape.

> Note that this will require SequenceScape to have already been [setup](https://github.com/sanger/sequencescape/blob/develop/README.md) before

1. The post deploy task will generate required records for Record Loader if they haven't been already. In a Sequencescape terminal, perform the post deploy actions:

   ```shell
   bundle exec rake application:post_deploy
   ```

1. In the same terminal, start the local server (will start on port 3000):

   ```shell
   bundle exec rails s
   ```

1. Open a **second** SequenceScape terminal, start the delayed job processor. This ensures that background processes are being handled:

   ```shell
   bundle exec rake jobs:work
   ```

All the setup for SequenceScape will have been completed. This should be done first as Limber will rely on some of the data generated previosly.

Only one terminal for Limber is needed (unless running the integration suite)

1. In Limber, ensure the appropriate version of Ruby is installed. The command
   here is for `rbenv` but you may want to use a different Ruby version manager:

   ```shell
   rbenv install
   ```

1. In Limber, make the Bundler gem install the dependencies for this project:

   ```shell
   bundle install
   ```

1. In Limber, install the yarn dependencies:

   ```shell
   nvm use  # If you manage node environments with nvm
   yarn install
   ```

1. In Limber, connect to Sequencescape to configure required data. This requires SequenceScape to be running, which will have been done in the previous steps:

   ```shell
   bundle exec rake config:generate
   ```

1. In Limber, start the local server (will start on port 3001):

   ```shell
   bundle exec rails s
   ```

## Linting and formatting

Linting and formatting are provided by rubocop, prettier and Eslint. I strongly
recommend checking out editor integrations. Also, using lefthook will help
ensure that only valid files are committed.

```shell
# Run rubocop
bundle exec rubocop
# Run rubocop with safe autofixes
bundle exec rubocop -a
# ESlint
yarn lint
# Check prettier formatting
yarn prettier --check .
# Fix prettier formatting
yarn prettier --write .
```

## Troubleshooting

If during development changes do not seem to be taking effect, try:

- Restart the application:
- Destroy and recreate the Docker container `docker-compose down && GENERATE_CONFIG=false docker-compose up -d`
- Rebuild the Docker image, particularly useful for changing dependencies
- Clobber local resources `rails assets:clobber`

## Note about the remainder of this document

The rest of the sections shown here were written for and apply to the native
installation, but can also be used in the Docker container if required. In order
to use Docker, it's probably best to create a shell in the running container.
Assuming you started the container via `docker-compose` you can access the shell
using:

```shell
docker exec -ti limber_limber_1 bash
```

If the container isn't recognised, check the container name (right hand column)
using `docker ps --all`, ensure it's up/running and substitute the name into the
above command in place of `limber_limber_1`.

## Docs

In addition to the [externally hosted YARD docs](https://www.rubydoc.info/github/sanger/limber), you can also run a local server:

```shell
yard server -r --gems -m limber
```

You can then access the Limber documentation through: [http://localhost:8808/docs/limber](http://localhost:8808/docs/limber)
Yard will also try and document the installed gems: [http://localhost:8808/docs](http://localhost:8808/docs)

## Configuring pipelines

{file:docs/configuring_new_pipelines.md Configuring new pipelines}

## Running Specs

### RSpec

Ruby unit and feature tests:

```bash
bundle exec rspec
```

### Jest

JavaScript unit tests:

```bash
yarn test
yarn test "path/to/file" -t "name of the test"
```

### Writing specs

There are a few tools available to assist with writing specs:

#### Factory Bot

- Strategies: You can use json `:factory_name` to generate the json that the API is expected to receive. This is very useful for mocking web responses. The association strategy is used for building nested json, it will usually only be used as part of other factories.

- Traits:

  - `api_object`: Ensures that lots of the shared behaviour, like actions and uuids are generated automatically
    barcoded: Automatically ensures that barcode is populated with the correct hash, and calculates human and machine barcodes
  - `build`: Returns an actual object, as though already found via the api. Useful for unit tests

- Helpers: `with_has_many_associations` and `with_belongs_to_associations` can be used in factories to set up the relevant json. They won't actually mock up the relevant requests, but ensure that things like actions are defined so that the api knows where to find them.

#### Request stubbing

Request stubs are provided by webmock. Two helper methods will assist with the majority of mocking requests to the api, `stub_api_get` and `stub_api_post`. See `spec/support/api_url_helper.rb` for details.

**Note**: Due to the way the api functions, the factories don't yet support nested associations.

### Lefthook

[Lefthook](https://github.com/Arkweid/lefthook) is a git-hook manager that will
ensure staged files are linted before committing.

You can install it either via homebrew `brew install Arkweid/lefthook/lefthook` or rubygems `gem install lefthook`

You'll then need to initialize it for each repository you wish to track `lefthook install`

Hooks will run automatically on commit, but you can test them with: `lefthook run pre-commit`

In addition you can also run `lefthook run fix` to run the auto-fixers on staged files only.
Note that after doing this you will still need to stage the fixes before committing. I'd love to be
able to automate this, but haven't discovered a solution that maintains the ability to partially
stage a file, and doesn't involve running the linters directly on files in the .git folder.

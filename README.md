# Limber Pipeline Application

![Linting](https://github.com/sanger/limber/workflows/Linting/badge.svg)
![Ruby RSpec Tests](https://github.com/sanger/limber/workflows/Ruby%20RSpec%20Tests/badge.svg)
![Javascript testing](https://github.com/sanger/limber/workflows/Javascript%20testing/badge.svg)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/limber)

## Description

A flexible front end to pipelines in Sequencescape.

## User Requirements

- Used on laboratory instrument machines often running older browser versions due to vendor and network limitations.
  The user-agent strings extracted from the nginx access logs of August 2024 indicate that the the oldest browser suspected of using Limber is Chrome 65. This means that the minified code served to browsers should be compatible with [ECMAScript 2018](https://www.w3schools.com/js/js_2018.asp).
  Please see the [Limber page on Confluence](https://ssg-confluence.internal.sanger.ac.uk/display/PSDPUB/LIMBer) for more information.

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
docker compose up
```

Variations on this command include:

- `docker compose up -d` which starts the container as a background task
  (freeing up the terminal). You can then use `docker compose down` to turn it
  off again.
- `GENERATE_CONFIG=false docker compose up` which will avoid running the
  `config:generate` rake task as Limber is started.
- `PRECOMPILE_ASSETS=false docker compose up` which will avoid precompiling the
  assets as Limber is started.
- `docker compose up --build` which forces a rebuild of the Docker image if your
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

1. In a second Limber terminal, start the Vite development server for faster development of frontend resources (will start on port 3036):

   ```shell
   yarn dev
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

### ViteRuby::MissingEntrypointError in Search#new

If you see an error like this:

```
Showing /code/app/views/layouts/application.html.erb where line #10 raised:

Vite Ruby can't find entrypoints/application.css in the manifests.

Possible causes:
  - The last build failed. Try running `bin/vite build --clear --mode=development` manually and check for errors.

Errors:
  /code/node_modules/rollup/dist/native.js:59
  		throw new Error(
```

Then you may need to run `bin/vite build --clear --mode=development` as suggested, and reload the page.

Alternatively, run `./compile_build.sh` to compile the build files or run `yarn dev` to start the Vite development server.

### Changes not updating

If during development changes do not seem to be taking effect, try:

- Restart the application:
- Destroy and recreate the Docker container `docker compose down && GENERATE_CONFIG=false docker compose up -d`
- Rebuild the Docker image, particularly useful for changing dependencies
- Clobber local resources `rails assets:clobber`

## Note about the remainder of this document

The rest of the sections shown here were written for and apply to the native
installation, but can also be used in the Docker container if required. In order
to use Docker, it's probably best to create a shell in the running container.
Assuming you started the container via `docker compose` you can access the shell
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

### Vitest

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

#### Request stubbing for the Sequencescape v1 API

Request stubs are provided by webmock. Two helper methods will assist with the majority of mocking requests to the api, `stub_api_get` and `stub_api_post`. See `spec/support/api_url_helper.rb` for details.

**Note**: Due to the way the api functions, the factories don't yet support nested associations.

#### Request stubbing for the Sequencescape v2 API

The V2 API uses `JsonApiClient::Resource` sub-classes to represent the records in memory.
Generally these are quite dynamic so you don't need to explicitly specify every property the API will respond with.
The base class also provides us with methods that are familiar to Rails for finding one or more records that match criteria.
So to stub the API, the easiest thing to do is to get FactoryBot to make up resources using the specific resource sub-class for the V2 API, and then mock the calls to those lookup methods.
Many of these have already been done for you in `spec/support/api_url_helper.rb` such as `stub_v2_study` and `stub_v2_tag_layout_templates` which sets up the `find` method for studies by name and the `all` method for tag layout templates, respectively.
However there's also `stub_api_v2_post`, `stub_api_v2_patch` and `stub_api_v2_save` which ensures that any calls to the `create`, `update` and the `save` method for resources of a particular type are expected and give a return value.
If none of the existing method suit your needs, you should add new ones.

##### FactoryBot is not mocking my related resources correctly

Nested relationships, such as Wells inside a Plate, the resource should indicate this with keywords like `has_one`, `has_many`, `belongs_to`, etc.
See the [json_api_client repository](https://github.com/JsonApiClient/json_api_client) for this topic and more.
However, FactoryBot does not get on well with some of these relationship methods and will not mock them properly using standard FactoryBot definitions.

If you find that FactoryBot is not giving you the expected resource for a related record, you can inject the related resource directly into the `JsonApiClient::Resource`'s cache of relationships.
To do that, define the related resource as a `transient` variable and use an `after(:build)` block to assign the resource to the `_cached_relationship` method.
For example, where the Resource might be defined as the following class:

```ruby
class Sequencescape::Api::V2::RootRecord < JsonApiClient::Resource
  has_one :related_thing
end
```

You might expect to be able to use FactoryBot in the following way:

```ruby
FactoryBot.define do
  factory :root_record, class: Sequencescape::Api::V2::RootRecord do
    skip_create

    related_thing { create :related_thing }
  end
end
```

But the related thing will not be the one you defined to be generated by another factory.
It appears the `has_one` method in the resource over-rides the mocked value and you get an empty record back instead.
So, instead, you should create the `related_thing` record as a transient and assign it to the `root_record` in an `after(:build)` block as shown here.

```ruby
FactoryBot.define do
  factory :root_record, class: Sequencescape::Api::V2::RootRecord do
    skip_create

    transient { related_thing { create :v2_tag_group_with_tags } }

    after(:build) do |record, factory|
      record._cached_relationship(:related_thing) { factory.related_thing } if evaluator.related_thing
    end
  end
end
```

#### Feature debugging

To help with debugging feature specs, temporarily comment out the line `options.add_argument('--headless')` in `spec/spec_helper.rb`. This will allow you to see the browser as the tests run. To pause the execution at certain point, possibly before an expected failure, insert `binding.pry` at the appropriate place in the spec.

To save a screenshot of the browser, insert the line below into the spec.

```rb
save_screenshot("#{Time.now.iso8601}.png")
```

Screenshots will be saved to `tmp/capybara/`.

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

# Limber Pipeline Application

![Linting](https://github.com/sanger/limber/workflows/Linting/badge.svg)
![Ruby RSpec Tests](https://github.com/sanger/limber/workflows/Ruby%20RSpec%20Tests/badge.svg)
![Javascript testing](https://github.com/sanger/limber/workflows/Javascript%20testing/badge.svg)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/limber)

## Description

A flexible front end to plate bases pipelines in Sequencescape

## Initial Setup

1. In Sequencescape, configure all Limber required data:
```shell
  bundle exec rake limber:setup
```

1. Start Sequencescape (will start in 3000):
```shell
  bundle exec rails s
```

1. In Limber, connect to Sequencescape to configure required data:
```shell
  bundle exec rake config:generate
```

1. Start Limber (will start in 3001):
```shell
  bundle exec rails s
```

## Docs

In addition to the [externally hosted YARD docs](https://www.rubydoc.info/github/sanger/limber), you can also run a local server:

```shell
yard server -r --gems -m limber
```

You can then access the Limber documentation through: http://localhost:8808/docs/limber
Yard will also try and document the installed gems: http://localhost:8808/docs

## Configuring pipelines

{file:docs/configuring_new_pipelines.md Configuring new pipelines}

## Running Specs

### RSpec

Ruby unit and feature tests:

```bash
    bundle exec rspec
```

### Karma

JavaScript unit tests:

```bash
    yarn karma start --single-run
```

If you get '[Webpacker] Compilation Failed' when trying to run specs, you might need to get yarn to install its dependencies properly. One way of doing this is by precompiling the assets:

```bash
    yarn
    rake assets:precompile
```

This has the added benefit that it reduces the risk of timeouts when the tests are running, as assets will not get compiled on the fly.

### Writing specs

There are a few tools available to assist with writing specs:

#### Factory Bot

* Strategies: You can use json `:factory_name` to generate the json that the API is expected to receive. This is very useful for mocking web responses. The association strategy is used for building nested json, it will usually only be used as part of other factories.

* Traits:
  * `api_object`: Ensures that lots of the shared behaviour, like actions and uuids are generated automatically
barcoded: Automatically ensures that barcode is populated with the correct hash, and calculates human and machine barcodes
  * `build`: Returns an actual object, as though already found via the api. Useful for unit tests

* Helpers: `with_has_many_associations` and `with_belongs_to_associations` can be used in factories to set up the relevant json. They won't actually mock up the relevant requests, but ensure that things like actions are defined so that the api knows where to find them.

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

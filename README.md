# Limber Pipeline Application

[![Build Status](https://travis-ci.org/sanger/limber.svg?branch=develop)](https://travis-ci.org/sanger/limber)
[![Yard Docs](http://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/github/sanger/limber)

A flexible front end to plate bases pipelines in [Sequencescape](https://github.com/sanger/sequencescape).

## Contents

<!-- toc -->

* [Setup](#setup)
  * [Ruby](#ruby)
  * [Gems](#gems)
  * [Node packages](#node-packages)
* [Runnning](#runnning)
  * [Rails server](#rails-server)
  * [Webpacker](#webpacker)
* [Testing](#testing)
  * [RSpec](#rspec)
  * [Karma](#karma)
* [Writing specs](#writing-specs)
  * [Factory Bot](#factory-bot)
  * [Request stubbing](#request-stubbing)

<!-- tocstop -->

## Installation

### Ruby

The ruby version is found in `.ruby-version`. Install this version using rbenv or rvm.

### Gems

Gems are managed using [bundler](https://bundler.io/), to install bundler, run:

```shell
gem install bundler
```

Then install the gems found in `Gemfile` using

```shell
bundle install
```

### Node packages

Install the required node packages (found in `package.json`) using:

```shell
bundle exec rails yarn:install
```

## Config and runnning

### Configuration

Limber needs to be pointed at an instance of Sequencescape by editing/copying the config file
like `config/environments/development.rb`. Once the required API endpoints have been configured,
the config rake task needs to be run:

```shell
bundle exec rake config:generate
```

### Rails server

To run the rails sever:

```shell
bundle exec rails server
```

### Webpacker

You will need to run `webpack-dev-server` when developing to ensure all the vue.js javascript is
correctly compiled.

## Testing

### RSpec

Ruby unit and feature tests:

```shell
bundle exec rspec
```

### Karma

JavaScript unit tests:

```shell
yarn karma start --single-run
```

If you get '[Webpacker] Compilation Failed' when trying to run specs, you might need to get yarn to
install its dependencies properly. One way of doing this is by precompiling the assets:

```shell
yarn
bundle exec rake assets:precompile
```

This has the added benefit that it reduces the risk of timeouts when the tests are running, as
assets will not get compiled on the fly.

## Writing specs

There are a few tools available to assist with writing specs:

### Factory Bot

* Strategies: You can use JSON `:factory_name` to generate the JSON that the API is expected to
receive. This is very useful for mocking web responses. The association strategy is used for
building nested JSON, it will usually only be used as part of other factories.

* Traits:
  * `api_object`: Ensures that lots o the shared behaviour, like actions and UUIDs are generated
                  automatically
  * `barcoded`: Automatically ensures that barcode is populated with the correct hash,
                and calculates human and machine barcodes
  * `build`: Returns an actual object, as though already found via the API. Useful for unit tests

* Helpers: `with_has_many_associations` and `with_belongs_to_associations` can be used in factories
to set up the relevant JSON. They won't actually mock up the relevant requests, but ensure that
things like actions are defined so that the API knows where to find them.

### Request stubbing

Request stubs are provided by webmock. Two helper methods will assist with the majority of mocking
requests to the API, `stub_api_get` and `stub_api_post`. See [api_url_helper.rb](https://github.com/sanger/limber/blob/develop/spec/support/api_url_helper.rb)
for details.

**Note**: Due to the way the API functions, the factories don't yet support nested associations.

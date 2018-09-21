Limber Pipeline Application
=============================

[![Build Status](https://travis-ci.org/radome/limber.svg?branch=test_openstack)](https://travis-ci.org/radome/limber)

Description
-----------

A flexible front end to plate bases pipelines in Sequencescape


Running Specs
-------------

If you get '[Webpacker] Compilation Failed' when trying to run specs, you might need to get yarn to install its dependencies properly. One way of doing this is by precompiling the assets:

```
    yarn
    rake assets:precompile
```

This has the added benefit that it reduces the risk of timeouts when the tests are running, as assets will not get compiled on the fly.


Webpacker
---------

You'll need to run `webpack-dev-server` when developing to ensure all the vue.js javascript is correctly compiled.


Writing specs
-------------

There are a few tools available to assist with writing specs:

#### Factory Bot

* Strategies: You can use json `:factory_name` to generate the json that the API is expected to receive. This is very useful for mocking web responses. The association strategy is used for building nested json, it will usually only be used as part of other factories.

* Traits:
    * `api_object`: Ensures that lots o the shared behaviour, like actions and uuids are generated automatically
barcoded: Automatically ensures that barcode is populated with the correct hash, and calculates human and machine barcodes
    * `build`: Returns an actual object, as though already found via the api. Useful for unti tests

* Helpers: `with_has_many_associations` and `with_belongs_to_associations` can be used in factories to set up the relevant json. They won't actually mock up the relevant requests, but ensure that things like actions are defined so that the api knows where to find them.

#### Request stubbing

Request stubs are provided by webmock. Two helper methods will assist with the majority of mocking requests to the api, `stub_api_get` and `stub_api_post`. See `spec/support/api_url_helper.rb` for details.

**Note**: Due to the way the api functions, the factories don't yet support nested associations.

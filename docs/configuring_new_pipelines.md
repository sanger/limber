<!--
# @markup markdown
# @title Configuring new pipelines
-->

# Configuring new pipelines

## Outline

A 'pipeline' as described during development discussions with users may comprise a number of sub-sections. For example, a 'pipeline' might include a sample prep section (to prepare the DNA), and a library prep section (to create the libraries for sequencing). Or may contain a branch point where the 'pipeline' can diverge into several different library prep sub-sections. Each sub-section will typically have it's own Submission template, to track that part of the overall work.
In Limber, it is these sub-sections that are defined as 'pipeline' configurations. For example, for Bioscan we have a Bioscan Lysate preparation pipeline that then leads into a Bioscan Library prep pipeline. Two Submissions for two distinct parts of the process carried out by different labs. Together, they make up the 'Bioscan pipeline' that the users will refer to.

So a Limber pipeline describes the way in which samples may be processed through a series of tracked steps within in lab. While processing samples through a pipeline, the lab staff will use multiple specific instances of labware (eg. plates, tubes and tube racks), and will transfer the samples between these as they progress. Each labware instance is uniquely barcoded. At each step of the pipeline some kind of chemical process or cleanup is happening to the samples. Each of these steps is assigned a particular configuration 'purpose' when it is created, which establishes how it behaves, and how it is displayed to the user. And a pipeline can be defined by describing the series of relationships between these different purposes, e.g. purpose A leads on to purpose B, purpose B leads on to purpose C etc.

While Limber offers the flexibility to deviate from the prescribed pipelines,
the pipeline configuration determines the recommended route through the process. The next step is displayed to the user as the next 'suggested action', and is followed in the vast majority of cases.

Where liquid handler robots are used to perform the sample transfers between labwares, there will also be configuration for the bed verification. A bed verification describes which beds on the robot deck the labwares must be placed in. The user scans a barcode on the bed, and the barcode on the labware, and the system checks that the purpose of the scanned labware matches the purpose that is supposed to be placed into that bed. It also checks that the parent and child labwares are correctly related in the LIMS. The intention is to prevent swaps, where you've mistakenly picked up an incorrect labware for a transfer. This is easy to do otherwise, given the child labware is typically empty and a high throughput pipeline will have multiple labwares of samples in progress at any given time.

Purposes also define any file exports for the labware. These can include concentration files, liquid handler driver files, and reports.

A pipeline is configured in these locations in Limber:

1. `config/purposes/*.yml` - labware purpose configurations
2. `config/pipelines/*.yml` - pipeline configurations
3. `config/robots.rb` - bed verifications
4. `config/exports.yml` and `app/views/exports/*.erb` - file exports

And in these locations in Sequencescape:

1. `config/default_records/*.yml` Record loader files in Sequencescape
2. And for older pipelines in the `limber.rake` task in Sequencescape

### Patterns

See [`docs/pipeline_patterns.md`](./pipeline_patterns.md) for some common issues and how to resolve them.
 for examples of how to do more complex functionality in pipelines like splitting and re-merging, branching, automated submissions, etc.

## Limber

### `config/purposes/*.yml`

Describes each purpose in the pipeline, and how it behaves.
See [`docs/purposes_yaml_files.md`](./purposes_yaml_files.md) for some common issues and how to resolve them.


Labware creators specified in the purposes configuration are responsible for creating new labwares.
See [`docs/creators.md`](./creators.md) for some common issues and how to resolve them.


Presenters specified in the purposes configuration are responsible for displaying the labwares.
See [`docs/presenters.md`](./presenters.md) for some common issues and how to resolve them.


### `config/pipelines/*.yml`

Describes how the purposes link together, and how you know which pipeline you
are following.
See [`docs/pipelines_yaml_files.md`](./pipelines_yaml_files.md) for some common issues and how to resolve them.


### `config/robots.rb`

Describes the bed verifications, defining which labware purposes are valid for a specific transfer. These are used to prevent mistakes loading liquid handler robots.
See [`docs/robots_file.md`](./robots_file.md) for some common issues and how to resolve them.


### `config/exports.yml` and `app/views/exports/*.erb`

Describes the files that can be downloaded from labware purposes, defining their format and what information they contain. Typically QC data and robot driver files, but can be anything the pipeline step requires.
See [`docs/exports_files.md`](./exports_files.md) for some common issues and how to resolve them.


## Sequencescape

Limber is used to process the requests created in Sequencescape when the SSR makes a Submission for work on a customers behalf. A Submission can contain many Orders, and each Order can contain many Requests. These Requests identify what work is requested through a combination of key, request_type and library_type (for library prep Submissions). They may also specify other customer requested variables, such as primer_panels or bait libraries.

One issue with the configuration of Submissions and Requests in Sequencescape is that it requires any Labware purposes it references to have been created in the database first. e.g. a request type definition needs to include a set of 'allowed purposes' on which it may be submitted. And typically we deploy Sequencescape before Limber so the purpose may not exist yet.
In Limber the same purpose configuration includes additional Limber-specific elements, such as references to the Labware Creator model, Presenter view, and any file exports or bed verifications, which are unknown to Sequencescape and not database persisted.

So we have to define the initial labwares for any pipeline that submissions are created on (typically any 'input' and 'stock' flagged purposes) in Sequencescape, as well as in Limber.
This configuration duplication is the subject of technical backlog stories to resolve in the future.

Pipeline configuration in Sequencescape is persisted into the database in two ways, either by using Record Loader or in the limber.rake task.

### Record Loader files

Using Record Loader is now the prefered way to set up submission templates, request types, and initial labware purposes (amongst other configuration data).
See `https://github.com/sanger/record_loader`

### limber.rake task

The limber.rake task defines some request types and library types, and helps set up some of the submission templates that the SSRs use to generate submissions. This is the deprecated way that configuration used to be set up in Sequencescape for pipelines.
Record Loader is preferred for any new configuration going forward.

## Testing a Limber Pipeline

Integration testing for a Limber pipeline is done in the Integration Suite repository.
See `https://gitlab.internal.sanger.ac.uk/psd/integration-suite`

This is an RSpec based series of tests that use Capybara and Playwright to run through the Limber pipelines clicking on buttons and entering values in a similar way that a user would.

There is one test per pipeline, which typically tests the main path through that pipeline. The tests do not necessarily check every possible route through the pipeline, or all the error handling, and usually use a simple submission and minimal numbers of samples for speed.

These tests are very useful during pipeline development, and one should be created in parallel as you develop any new pipeline.

The tests are also very useful for demos to users, for support purposes to get to specific steps, and for data setup when doing UAT's of new functionality or fixes at certain steps.

They are less useful for volume testing, non-standard route testing, and for setting up more complex test data (e.g. complex pooling submissions).

## Troubleshooting configuration issues

It can be frustrating to debug issues with Sequencescape and Limber pipeline configuration.
See [`docs/troubleshooting.md`](./troubleshooting.md) for some common issues and how to resolve them.

<!--
# @markup markdown
# @title Configuring new pipelines
-->

# Configuring new pipelines

## Outline

A pipeline describes the way in which samples may be processed in lab to produce
a library. While processing samples through a pipeline, the users can be
expected to create multiple pieces of labware (eg. plates, tubes), and transfer
samples between these. Each labware has a particular 'purpose' which established
how it behaves, and is displayed to the user. Multiple purposes are linked
together to establish the pipeline.

While Limber offers the flexibility to deviate from the prescribed pipelines,
the configuration here determines the recommended route through the process,
and the one followed in the vast majority of cases.

A pipeline is configured in three main locations:

  1. `config/purposes/*.yml`
  2. `config/pipelines/*.yml`
  3. And in the limber.rake task in Sequencescape

## `config/purposes/*.yml`

Describes each purpose in the pipeline, and how it behaves.
{file:docs/purposes_yaml_files.md}

## `config/pipelines/*.yml`

Describes how the purposes link together, and how you know which pipeline you
are following.
{file:docs/pipelines_yaml_files.md}

## Sequencescape

Limber processes requests created in Sequencescape when the SSR makes a
submission. These requests identify what work is requested through a
combination of request_type and library_type, and also specify other
customer requested variables, such as primer_panels or bait libraries.

The limber.rake task defines the request types and library types, and
helps set up the submission templates that the SSRs will use to generate
the submissions.

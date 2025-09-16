<!--
# @markup markdown
# @title Troubleshooting
-->

# Troubleshooting Pipeline Configuration Issues

It can be difficult to debug problems when developing a new pipeline. Here is an attempt to document the most common issues and what to do about them.

## Deploying new pipelines

It is important to understand the order of configuration setup and what is happening.

Sequencescape should be deployed first.
Deployment automatically runs the `rake limber:setup` and `rake application:post_deploy` tasks.
These tasks use the configuration for any stock/input labware purposes, request types, submission templates, tag groups, robots and other entities to persist any new information into the Sequencescape database.

Limber should be deployed second.
Deployment automatically runs the `rake config:generate` task.
This task checks that the purposes in the Limber configuration exist in the Sequencescape database and creates any that do not exist. It does NOT overwrite or update a purpose that already exists. This includes stock/input labware purposes configured in Sequencescape.
Additionally, this task generates the `config/settings/<ENVIRONMENT>.yml` file on the server which Limber uses as local configuration.
This file contains purpose, submission template and robot bed verification configuration all in one place, keyed using the UUIDs of the objects fetched from Sequencescape. This information is far more detailed and Limber focused than that stored in the database.

> [TIP]
Some things to be aware of when deploying new or modified configuration:
> - Purpose and bed verification names must be unique within the Limber configuration. NB. For stock/input labwares there will be purpose config for the same purpose name in both Sequencescape and Limber.
> - Limber purpose configuration is not fully persisted into the Sequencescape database. Most of the Limber-specific configuration is only written into the `config/settings/<ENVIRONMENT>.yml` file on the server.
> - Purposes that already exist in the database from a previous deployment will not be overriden or updated if you change the Limber purposes yaml file configuration. For example, changing the `type` (purpose class) will not be updated in the database, but will be updated in the `config/settings/<ENVIRONMENT>.yml` file, causing a mismatch. In these cases you have to manually update the database (using rails console where possible).

## Labware is not a Limber Labware

Scenario: viewing a labware in Limber displays a warning message that '<Purpose Name> is not a Limber plate. Perhaps you are using the wrong pipeline application?'

This indicates that the UUID of this plate purpose does not match to one in the `config/settings/<ENVIRONMENT>.yml`.

> [Check]
> - Is the labware you are trying to display in Limber a labware that's configured in the Limber purposes? Some labwares are for Sequencescape pipelines or functionality and are not configured for Limber.
> - Have you run `bundle exec rake config:generate` in Limber before starting your Limber server? This queries Sequencescape to fetch (or create and fetch) the UUID for each purpose in the Limber purposes configs and writes them to `config/settings/<ENVIRONMENT>.yml`.
> - Have you pointed your local Sequencescape and Limber servers to the database of a different environment e.g. UAT? If so you need to run `bundle exec rake config:generate` to update the UUIDs in the `config/settings/<ENVIRONMENT>.yml` to those in that environment.

## Suggested action button not visible

Scenario: the expected green suggested action button does not appear

> [Check]
> - Are you logged on to Limber? Limber requires you to be logged in before you can create labwares. You can view without logging in, but will not see the suggested action buttons to create child labwares. You can set up your Limber swipecard in Sequencescape -> edit profile top right (it can be any string).
> - Is the labware in the correct state to allow creation of children? Usually it must be in 'passed' state unless you are using a `PermissivePresenter`.
> - Have you run `rake application:post_deploy` on your Sequencescape server, and `rake config:generate` on your Limber server before starting them? If Limber hasn't created the `config/settings/<ENVIRONMENT>.yml` file with up to date UUIDs it won't be able to work out the next step.
> - Does your labware meet the filter citeria in your pipeline configuration to allow the next action to be suggested? Check for typos in purpose names, request types and library types. Check the correct submission has been made and requests created on your samples (use rails console to check). Check the correct relationship parent to child line is present in your pipeline configuration.
> - Is your Sequencescape jobs worker running to asynchronously process the Submissions? Without it requests won't be generated on your samples, and the filter in your pipeline configuration will not match. In a terminal in Sequencescape root run `bundle exec rake jobs:work`.

## Labware creation failed

Scenario: clicking the suggested action button to create the child results in a labware creation controller error.

> [Check]
> - Have you reset your Sequencescape database, or pointed your local Sequencescape and Limber servers to a database in a different environment, but not logged out and back in to Limber in the browser? Limber stores your user UUID in the browser session, so if you have not logged out and back in after a database change the UUID will not reflect a valid user. A valid user is required for Sequencescape to create the child labware.
N.B. For a database reset you will have to recreate your swipecard in Sequencescape.

## Robot bed verification button(s) are not showing

Scenario: Bed verifications defined are defined in `config/robots.rb`. The expected bed verification button(s) are not showing when you view a labware in Limber.

> [Check]
> - Have you run `rake config:generate` on your Limber server? Bed verification configuration from `config/robots.rb` is written into the `config/settings/<ENVIRONMENT>.yml` file by this task.
> - Does the purpose name and states list specified in the bed verification configuration match to the current labware purpose name and state? These bed values act as filters to limit when the buttons show.

## File links are not showing

Scenario: File links are configured in the purposes yaml files. This purpose configuration uses keys that are linked in the `config/exports/exports.yml` file to the relevant exports files under {ExportsController}. The expected file download buttons are not showing when you view a labware in Limber.

> [Check]
> - Have you run `rake config:generate` on your Limber server? The `file_links` in purpose configurations are written into the `config/settings/<ENVIRONMENT>.yml` file by this task.
> - Do the keys and filenames match precisely? The `id` value in the `file_links` section in the purpose configuration needs to match to a key in the `config/exports/exports.yml` file. And in turn, the value for `csv` in that export yaml file needs to match to an export filename, most of which are in `app/views/exports`.
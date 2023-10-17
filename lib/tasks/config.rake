# frozen_string_literal: true

require_relative '../purpose_config'
require_relative '../config_loader/purposes_loader'

namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require './config/robots'

  task generate: :environment do
    begin
      api = Sequencescape::Api.new(Limber::Application.config.api.v1.connection_options)
    rescue Sequencescape::Api::UnauthenticatedError => _e
      puts <<~HEREDOC
        Could not authenticate with the Sequencescape API
        Check config.api.v1.connection_options.authorisation in config/environments/#{Rails.env}.rb
        The value should be listed in the api_applications table of the Sequencescape instance
        you are connecting to.
        In development mode it is recommended that you set the key through the API_KEY environment
        variable. This reduces the risk of accidentally committing the key.
      HEREDOC
      exit 1
    end

    label_templates = YAML.load_file(Rails.root.join('config/label_templates.yml'))

    puts 'Fetching submission_templates...'
    submission_templates = api.order_template.all.each_with_object({}) { |st, store| store[st.name] = st.uuid }

    puts 'Fetching purposes...'
    query = Sequencescape::Api::V2::Purpose.select(:uuid, :name).paginate(per_page: 100)
    all_purposes = Sequencescape::Api::V2.merge_page_results(query).index_by(&:name)

    purpose_config =
      ConfigLoader::PurposesLoader.new.config.map do |name, options|
        PurposeConfig.load(name, options, all_purposes, api, submission_templates, label_templates)
      end

    puts 'Preparing purposes...'
    tracked_purposes = purpose_config.map { |config| all_purposes[config.name] ||= config.register! }

    # Build the configuration file based on the server we are connected to.
    CONFIG = # rubocop:todo Lint/ConstantDefinitionInBlock
      {}.tap do |configuration|  # rubocop:todo Metrics/BlockLength
        puts 'Preparing searches ...'
        configuration[:searches] =
          api.search.all.each_with_object({}) { |search, searches| searches[search.name] = search.uuid }

        puts 'Preparing transfer templates ...'
        configuration[:transfer_templates] =
          api
            .transfer_template
            .all
            .each_with_object({}) do |transfer_template, transfer_templates|
              transfer_templates[transfer_template.name] = transfer_template.uuid
            end

        configuration[:printers] =
          {}.tap do |printers|
            printers[:plate_a] = 'g316bc'
            printers[:plate_b] = 'g311bc2'
            printers[:tube_rack] = 'heron-bc2'
            printers[:tube] = 'g311bc1'
            printers['limit'] = 5
            printers['default_count'] = 2
          end

        configuration[:purposes] =
          {}.tap do |labware_purposes|
            puts 'Preparing purpose configs...'
            purpose_config.each { |purpose| labware_purposes[purpose.uuid] = purpose.config }
          end

        configuration[:purpose_uuids] =
          tracked_purposes.each_with_object({}) { |purpose, store| store[purpose.name] = purpose.uuid }

        configuration[:robots] = ROBOT_CONFIG

        %i[default_pmb_templates default_sprint_templates default_printer_type_names].each do |key|
          configuration[key] = label_templates[key.to_s]
        end

        configuration[:submission_templates] = submission_templates
      end

    # Write out the current environment configuration file
    Rails.root.join('config', 'settings', "#{Rails.env}.yml").open('w') do |file|
      file.puts(
        [
          '# The current file has been automatically generated by running the task:',
          '#   > rake config:generate',
          '# It is recommended if you need to do any changes in config to modify the',
          '# required config file under config/pipelines or config/purposes and rerun',
          "# the task\n"
        ].join("\n")
      )
      file.puts(CONFIG.to_yaml)
    end

    Rake::Task['docs:update'].invoke if Rails.env.development?
  end

  task default: :generate
end

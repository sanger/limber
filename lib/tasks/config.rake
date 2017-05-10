# frozen_string_literal: true

require_relative '../purpose_config'
namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require Rails.root.join('config', 'robots')

  task generate: :environment do
    api = Sequencescape::Api.new(Limber::Application.config.api_connection_options)

    all_purposes = api.plate_purpose.all.index_by(&:name).merge(api.tube_purpose.all.index_by(&:name))

    purpose_config = YAML.parse_file('config/purposes.yml').to_ruby.map do |name, options|
      PurposeConfig.load(name, options, all_purposes, api)
    end

    tracked_purposes = purpose_config.map do |config|
      all_purposes[config.name] ||= config.register!
    end

    # Build the configuration file based on the server we are connected to.
    CONFIG = {}.tap do |configuration|
      configuration[:large_insert_limit] = 250

      configuration[:searches] = {}.tap do |searches|
        puts 'Preparing searches ...'
        api.search.all.each do |search|
          searches[search.name] = search.uuid
        end
      end

      configuration[:transfer_templates] = {}.tap do |transfer_templates|
        puts 'Preparing transfer templates ...'
        api.transfer_template.all.each do |transfer_template|
          transfer_templates[transfer_template.name] = transfer_template.uuid
        end
      end

      configuration[:printers] = {}.tap do |printers|
        printers[:plate_a] = 'g316bc'
        printers[:plate_b] = 'g311bc2'
        printers[:tube]    = 'g311bc1'
        printers['limit'] = 5
        printers['default_count'] = 2
      end

      configuration[:purposes] = {}.tap do |labware_purposes|
        puts 'Preparing purpose configs...'
        purpose_config.each do |purpose|
          labware_purposes[purpose.uuid] = purpose.config
        end
      end

      configuration[:purpose_uuids] = tracked_purposes.each_with_object({}) do |purpose, store|
        store[purpose.name] = purpose.uuid
      end

      configuration[:robots]      = ROBOT_CONFIG
      configuration[:qc_purposes] = []

      configuration[:submission_templates] = {}.tap do |submission_templates|
        puts 'Preparing submission templates...'
        submission_templates['miseq'] = api.order_template.all.detect { |ot| ot.name == Limber::Application.config.qc_submission_name }.uuid
      end

      puts 'Setting study...'
      configuration[:study] = Limber::Application.config.study_uuid ||
                              puts('No study specified, using first study') ||
                              api.study.first.uuid
      puts 'Setting project...'
      configuration[:project] = Limber::Application.config.project_uuid ||
                                puts('No project specified, using first project') ||
                                api.project.first.uuid

      configuration[:request_types] = {}.tap do |request_types|
        request_types['illumina_htp_library_creation']    = ['Lib Norm', false]
        request_types['illumina_a_isc']                   = ['ISCH lib pool', false]
        request_types['illumina_a_re_isc']                = ['ISCH lib pool', false]
      end
    end

    # Write out the current environment configuration file
    File.open(Rails.root.join('config', 'settings', "#{Rails.env}.yml"), 'w') do |file|
      file.puts(CONFIG.to_yaml)
    end
  end

  task default: :generate
end

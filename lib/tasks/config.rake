# frozen_string_literal: true

require_relative '../purpose_config'

# rubocop:disable Metrics/BlockLength
namespace :config do
  desc 'Generates a configuration file for the current Rails environment'

  require Rails.root.join('config', 'robots')

  task generate: :environment do
    api = Sequencescape::Api.new(Limber::Application.config.api_connection_options)
    label_templates = YAML.parse_file(Rails.root.join('config', 'label_templates.yml')).to_ruby

    puts 'Fetching submission_templates...'
    submission_templates = api.order_template.all.each_with_object({}) { |st, store| store[st.name] = st.uuid }

    puts 'Fetching purposes...'
    all_purposes = api.plate_purpose.all.index_by(&:name).merge(api.tube_purpose.all.index_by(&:name))

    purpose_config = Rails.root.join('config', 'purposes').children.each_with_object([]) do |file, purposes|
      next unless file.extname == '.yml'
      YAML.parse_file(file).to_ruby.each do |name, options|
        purposes << PurposeConfig.load(name, options, all_purposes, api, submission_templates, label_templates)
      end
    end

    # Check for duplicates: We spread config over multiple files. If we have duplicates its going
    # to result in strange behaviour. So lets blow up early.
    if purpose_config.map(&:name).uniq!
      dupes = purpose_config.group_by(&:name).select { |_name, settings| settings.length > 1 }.keys
      raise StandardError, "Duplicate purpose config detected: #{dupes}"
    end

    puts 'Preparing purposes...'
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

      configuration[:robots] = ROBOT_CONFIG

      [:default_pmb_templates, :default_printer_type_names].each do |key|
        configuration[key] = label_templates[key.to_s]
      end
    end

    # Write out the current environment configuration file
    File.open(Rails.root.join('config', 'settings', "#{Rails.env}.yml"), 'w') do |file|
      file.puts(CONFIG.to_yaml)
    end
  end

  # rubocop:enable Metrics/BlockLength
  task default: :generate
end

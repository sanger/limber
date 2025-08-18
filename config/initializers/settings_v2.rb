# frozen_string_literal: true

# Parent settings mixin.
module SettingsV2
  CONFIGURATION_TYPES = %i[
    searches
    transfer_templates
    printers
    purposes
    purpose_uuids
    robots
    default_pmb_templates
    default_sprint_templates
    default_printer_type_names
    submission_templates
  ].freeze

  CONFIGURATION_TYPES.each do |config|
    # proc needs to return the configuration value
    self.class.send(:define_method, config, proc { configuration.send(config) })
  end

  def self.load_yaml
    config = Rails.root.join('config', 'settings', "#{Rails.env}.yml")
    return unless File.exist?(config)

    config_file_descriptor = File.open(configuration_filename, 'r:bom|utf-8')
    # Returns a Hash with the configuration data
    config_data = YAML.safe_load(config_file_descriptor, permitted_classes: [Symbol], aliases: true)
    raise "Configuration file #{config} is not valid YAML." if config_data.blank?

    config_data.with_indifferent_access
  end

  def self.configuration
    @configuration ||= ConfigurationV2.new(load_yaml)
  end
end

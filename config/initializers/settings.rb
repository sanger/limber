# frozen_string_literal: true

# Parent settings mixin.
module Settings
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
    poolings
  ].freeze

  # This loop declares Settings.<CONFIGURATION_TYPE> method declarations
  # using metaprogramming. For example, when it will add purposes method for Settings, and
  # when it is invoked, it will use the CustomConfiguration class to send the value for it.
  CONFIGURATION_TYPES.each do |config|
    # Accessor
    unless respond_to?(config)
      self.class.send(:define_method, config, proc {
        value = Settings.configuration.send(config)
        value.respond_to?(:children) ? value.children : value
      })
    end
    # Mutator
    next if respond_to?("#{config}=")

    # rubocop:disable Lint/DuplicateBranch
    self.class.send(:define_method, "#{config}=", proc { |value|
      config_value = Settings.configuration.send(config)
      if config_value.respond_to?(:children)
        if config_value.children.is_a?(Hash) && value.is_a?(Hash)
          config_value.children.replace(value)
        elsif config_value.children.is_a?(Array) && value.is_a?(Array)
          config_value.children.replace(value)
        else
          Settings.configuration.send("#{config}=", value)
        end
      else
        Settings.configuration.send("#{config}=", value)
      end
    })
    # rubocop:enable Lint/DuplicateBranch
  end

  # Delegates Settings.pipelines to the PipelinesLoader
  def self.pipelines
    @pipelines ||= ConfigLoader::PipelinesLoader.new.pipelines
  end

  def self.pipelines=(value)
    @pipelines = value
  end

  def self.load_yaml
    config = Rails.root.join('config', 'settings', "#{Rails.env}.yml")
    return unless File.exist?(config)

    config_file_descriptor = File.open(config, 'r:bom|utf-8')
    # Returns a Hash with the configuration data
    config_data = YAML.safe_load(config_file_descriptor, permitted_classes: [Symbol], aliases: true)
    raise "Configuration file #{config} is not valid YAML." if config_data.blank?

    config_data.with_indifferent_access
  end

  def self.configuration
    @configuration ||= CustomConfiguration.new(load_yaml)
  end
end

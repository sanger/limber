# frozen_string_literal: true

FactoryBot.define do
  # This factory creates a pooling configuration. The created object is a Hash
  # representing the configuration. The configuration is loaded from a YAML
  # file specified by the name transient attribute. The name attribute is the
  # filename without the extension in spec/fixtures/config/poolings/
  # directory. By default, the name is 'donor_pooling', and the factory loads
  # the configuration from 'donor_pooling.yml'. The loaded configuration is
  # assigned to a specific key in the `Settings.poolings` hash when the object
  # is created. The key is the same as the name transient attribute. This
  # factory includes a subfactory named `donor_pooling_config` to make it more
  # specific.
  #
  # Example usage:
  #   config = create(:pooling_config, name: 'donor_pooling')
  #   config = create(:donor_pooling_config)
  #
  # After running the above code, `Settings.poolings['donor_pooling']` will hold
  # the configuration loaded from 'donor_pooling.yml'. The Settings object will
  # be available with the specifid config in the tests.
  factory :pooling_config, class: Hash do
    transient do
      name { 'donor_pooling' } # Default name
    end

    pooling { YAML.load_file(Rails.root.join('spec/fixtures/config/poolings/', "#{name}.yml")) }

    # Initialise the instance that the factory creates. It assigns the pooling
    # configuration to a specific key in the Settings.poolings hash and then
    # returns the the pooling configuration.
    initialize_with do
      Settings.poolings ||= {}
      Settings.poolings.merge!(pooling)
      pooling
    end

    # Override the to_create method to prevent save! when using the factory.
    # This makes the create method to behave the same as build method.
    to_create do
      # Overridden to prevent calling save! on a Hash
    end

    # Use a specific name to create a donor pooling config.
    factory :donor_pooling_config do
      name { 'donor_pooling' }
    end
  end
end

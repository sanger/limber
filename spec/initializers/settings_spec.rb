# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe Settings, skip: 'WIP' do
  before do
    config = Rails.root.join('spec/data/config.yml')
    config_file_descriptor = File.open(config, 'r:bom|utf-8')
    # Returns a Hash with the configuration data
    config_data = YAML.safe_load(config_file_descriptor, permitted_classes: [Symbol], aliases: true)
    allow(described_class).to receive(:load_yaml).and_return(config_data)
    described_class.instance_variable_set(:@configuration, nil)
  end
end
# rubocop:enable RSpec/EmptyExampleGroup

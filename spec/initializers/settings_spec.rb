# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings, skip: 'Skipping as WIP' do
  let(:yaml_data) do
    {
      'searches' => %w[search1 search2],
      'transfer_templates' => ['template1'],
      'printers' => ['printer1'],
      'purposes' => ['purpose1'],
      'purpose_uuids' => ['uuid1'],
      'robots' => ['robot1'],
      'default_pmb_templates' => ['pmb1'],
      'default_sprint_templates' => ['sprint1'],
      'default_printer_type_names' => ['type1'],
      'submission_templates' => ['submission1'],
      'poolings' => ['pooling1']
    }
  end

  before do
    allow(Rails).to receive_messages(root: Pathname.new(File.dirname(__FILE__)), env: 'test')
    file_double = StringIO.new(yaml_data.to_yaml)
    allow(File).to receive_messages(exist?: true, open: file_double)
    stub_const('CustomConfiguration', Struct.new(*Settings::CONFIGURATION_TYPES) do
      def initialize(hash)
        hash.each { |k, v| send("#{k}=", v) }
      end
    end)
    described_class.instance_variable_set(:@configuration, nil)
  end

  describe 'Settings configuration setting the pipelines' do
    it 'when invoked, returns the pipelines properly' do
      skip 'WIP'
    end
  end
end

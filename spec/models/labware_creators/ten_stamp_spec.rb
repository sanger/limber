# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::TenStamp do
  subject { described_class.new(form_attributes) }

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent1_uuid } }

  let(:parent1_uuid) { 'parent1-plate-uuid' }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  context 'when purpose_config[:creator_class] is a string' do
    let!(:purpose_config) do
      create :aggregation_purpose_config,
             name: child_purpose_name,
             uuid: child_purpose_uuid,
             creator_class: 'LabwareCreators::TenStamp'
    end

    before { purpose_config }

    it 'returns an empty array' do
      expect(subject.acceptable_purposes).to eq([])
    end
  end

  context 'when purpose_config has acceptable_purposes' do
    let!(:purpose_config) do
      create :aggregation_purpose_with_args_config, name: child_purpose_name, uuid: child_purpose_uuid
    end

    before { purpose_config }

    it 'returns the acceptable_purposes array' do
      expect(subject.acceptable_purposes).to eq(%w[Purpose1 Purpose2])
    end
  end

  context 'when purpose_config does not have acceptable_purposes' do
    let!(:purpose_config) do
      create :aggregation_purpose_with_args_config,
             name: child_purpose_name,
             uuid: child_purpose_uuid,
             acceptable_purposes: nil
    end

    before { purpose_config }

    it 'returns an empty array' do
      expect(subject.acceptable_purposes).to eq([])
    end
  end

  context 'when purpose_config has request_type_keys' do
    let!(:purpose_config) do
      create :aggregation_purpose_with_args_config,
             name: child_purpose_name,
             uuid: child_purpose_uuid,
             request_type_keys: %w[request_type_1 request_type_2]
    end

    before { purpose_config }

    it 'returns the request_type_keys array' do
      expect(subject.request_type_keys).to eq(%w[request_type_1 request_type_2])
    end

    it 'uses the request type filter' do
      expect(subject.request_filter).to eq('request-type')
    end
  end

  context 'when purpose_config does not have request_type_keys' do
    let!(:purpose_config) do
      create :aggregation_purpose_with_args_config, name: child_purpose_name, uuid: child_purpose_uuid
    end

    before { purpose_config }

    it 'returns an empty array' do
      expect(subject.request_type_keys).to eq([])
    end

    it 'uses the null filter' do
      expect(subject.request_filter).to eq('null')
    end
  end
end

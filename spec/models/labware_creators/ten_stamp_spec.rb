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
end

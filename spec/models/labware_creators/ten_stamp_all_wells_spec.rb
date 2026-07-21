# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareCreators::TenStampAllWells do
  subject { described_class.new(form_attributes) }

  let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent1_uuid } }

  let(:parent1_uuid) { 'parent1-plate-uuid' }
  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let!(:purpose_config) do
    create :aggregation_purpose_config,
           name: child_purpose_name,
           uuid: child_purpose_uuid,
           creator_class: 'LabwareCreators::TenStampAllWells'
  end

  before { purpose_config }

  it 'returns true for transfer_all_wells?' do
    expect(subject.transfer_all_wells?).to be true
  end

  it 'inherits from TenStamp' do
    expect(described_class.superclass).to eq(LabwareCreators::TenStamp)
  end
end

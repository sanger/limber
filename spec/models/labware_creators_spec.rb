# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators'

# CreationForm is the base class for our forms
RSpec.describe LabwareCreators do
  let(:basic_purpose) { 'test-purpose' }
  let(:tagged_purpose) { 'dummy-purpose' }
  let(:partial_purpose) { 'partial-purpose' }

  before do
    create :purpose_config, creator_class: 'LabwareCreators::StampedPlate', uuid: basic_purpose
    create :purpose_config, creator_class: 'LabwareCreators::TaggedPlate', uuid: tagged_purpose
    create :purpose_config, uuid: partial_purpose
    Settings.purposes[partial_purpose].delete(:creator_class)
  end

  it 'can lookup form for a given purpose' do
    expect(LabwareCreators.class_for(basic_purpose)).to eq(LabwareCreators::StampedPlate)
  end

  it 'can lookup form for another purpose' do
    expect(LabwareCreators.class_for(tagged_purpose)).to eq(LabwareCreators::TaggedPlate)
  end

  it 'can handle partially configured purposes' do
    expect(LabwareCreators.class_for(partial_purpose)).to eq(LabwareCreators::Uncreatable)
  end
end

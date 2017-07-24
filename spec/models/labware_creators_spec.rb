# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators'

# CreationForm is the base class for our forms
describe LabwareCreators do
  let(:basic_purpose)  { 'test-purpose' }
  let(:tagged_purpose) { 'dummy-purpose' }

  before do
    Settings.purposes[basic_purpose] = {
      form_class: 'LabwareCreators::Base'
    }
    Settings.purposes[tagged_purpose] = {
      form_class: 'LabwareCreators::TaggedPlate'
    }
  end

  it 'can lookup form for a given purpose' do
    expect(LabwareCreators.class_for(basic_purpose)).to eq(LabwareCreators::Base)
  end

  it 'can lookup form for another purpose' do
    expect(LabwareCreators.class_for(tagged_purpose)).to eq(LabwareCreators::TaggedPlate)
  end
end

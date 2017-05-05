# frozen_string_literal: true

require 'spec_helper'
require 'forms/creation_form'

# CreationForm is the base class for our forms
describe Forms::CreationForm do
  let(:basic_purpose)  { 'test-purpose' }
  let(:tagged_purpose) { 'dummy-purpose' }

  before(:each) do
    Settings.purposes[basic_purpose] = {
      form_class: 'Forms::CreationForm'
    }
    Settings.purposes[tagged_purpose] = {
      form_class: 'Forms::TaggingForm'
    }
  end

  it 'can lookup form for a given purpose' do
    expect(described_class.class_for(basic_purpose)).to eq(Forms::CreationForm)
  end

  it 'can lookup form for another purpose' do
    expect(described_class.class_for(tagged_purpose)).to eq(Forms::TaggingForm)
  end

  context 'with a custom transfer-template' do
    before(:each) do
      Settings.purposes['test-purpose'] = { transfer_template: 'Custom transfer template' }
      Settings.transfer_templates['Custom transfer template'] = 'custom-template-uuid'
    end

    subject { Forms::CreationForm.new(purpose_uuid: 'test-purpose') }

    it 'can lookup form for another purpose' do
      expect(subject.transfer_template_uuid).to eq('custom-template-uuid')
    end
  end
end

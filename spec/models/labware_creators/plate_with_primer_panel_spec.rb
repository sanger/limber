# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/baited_plate'
require_relative 'shared_examples'

# A plate with primer panel has a preview page, but otherwise
# behaves exactly as a normal plate stamp
RSpec.describe LabwareCreators::PlateWithPrimerPanel do
  has_a_working_api
  it_behaves_like 'it only allows creation from plates'

  subject do
    LabwareCreators::PlateWithPrimerPanel.new(api, form_attributes)
  end

  let(:user_uuid)    { SecureRandom.uuid }
  let(:user)         { json :user, uuid: user_uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose)      { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid)  { SecureRandom.uuid }
  let(:plate_size)   { 384 }
  let(:parent)       { create :v2_plate_with_primer_panels, uuid: parent_uuid, size: plate_size, pool_sizes: [384] }

  let(:form_attributes) do
    {
      user_uuid: user_uuid,
      purpose_uuid: purpose_uuid,
      parent_uuid: parent_uuid
    }
  end

  before do
    Settings.purposes[purpose_uuid] = build :purpose_config, pcr_stage: 'pcr 1'
  end

  it 'should have page' do
    expect(LabwareCreators::PlateWithPrimerPanel.page).to eq 'plate_with_primer_panel'
  end

  # Essentially plate creation behaves as standard. The primer panel information
  # is solely for the user's benefit!
  context 'create plate' do
    let!(:plate_request) do
      stub_v2_plate(parent, stub_search: false)
    end

    let(:expected_transfers) { WellHelpers.stamp_hash(plate_size) }

    let!(:plate_creation_request) do
      stub_api_post('plate_creations',
                    payload: { plate_creation: {
                      parent: parent_uuid,
                      child_purpose: purpose_uuid,
                      user: user_uuid
                    } },
                    body: json(:plate_creation))
    end

    describe '#panel_name' do
      it 'extracts the panel name' do
        expect(subject.panel_name).to eq('example panel')
      end
    end

    describe '#pcr_program' do
      it 'extracts the pcr program name' do
        expect(subject.pcr_program).to eq('example program')
      end
    end

    describe '#pcr_duration' do
      it 'extracts the pcr duration' do
        expect(subject.pcr_duration).to eq('45 minutes')
      end
    end

    let!(:transfer_template_request) do
      stub_api_get('custom-pooling', body: json(:transfer_custom_pooling))
    end

    let!(:transfer_creation_request) do
      stub_api_post('custom-pooling',
                    payload: { transfer: {
                      destination: 'child-uuid',
                      source: parent_uuid,
                      user: user_uuid,
                      transfers: expected_transfers
                    } },
                    body: '{}')
    end

    it 'should create objects' do
      expect(subject.save!).to eq true
      expect(transfer_creation_request).to have_been_made
    end
  end
end

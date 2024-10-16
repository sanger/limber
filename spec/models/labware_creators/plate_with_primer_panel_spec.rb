# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/baited_plate'
require_relative 'shared_examples'

# A plate with primer panel has a preview page, but otherwise
# behaves exactly as a normal plate stamp
RSpec.describe LabwareCreators::PlateWithPrimerPanel do
  has_a_working_api
  it_behaves_like 'it only allows creation from plates'

  subject { LabwareCreators::PlateWithPrimerPanel.new(api, form_attributes) }

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:purpose) { json :purpose, uuid: purpose_uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:plate_size) { 384 }
  let(:requests) do
    Array.new(plate_size) do |i|
      create :gbs_library_request, state: 'started', uuid: "request-#{i}", submission_id: '2'
    end
  end
  let(:parent) do
    create :v2_plate_with_primer_panels,
           barcode_number: '2',
           uuid: parent_uuid,
           size: plate_size,
           outer_requests: requests
  end
  let(:child) { create :v2_plate_with_primer_panels, barcode_number: '3', size: plate_size, uuid: 'child-uuid' }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  before { create :purpose_config, pcr_stage: 'pcr 1', uuid: purpose_uuid }

  it 'should have page' do
    expect(LabwareCreators::PlateWithPrimerPanel.page).to eq 'plate_with_primer_panel'
  end

  # Essentially plate creation behaves as standard. The primer panel information
  # is solely for the user's benefit!
  context 'create plate' do
    let!(:plate_request) do
      stub_v2_plate(parent, stub_search: false)
      stub_v2_plate(child, stub_search: false)
    end

    let!(:plate_creation_request) do
      stub_api_post(
        'plate_creations',
        payload: {
          plate_creation: {
            parent: parent_uuid,
            child_purpose: purpose_uuid,
            user: user_uuid
          }
        },
        body: json(:plate_creation)
      )
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

    let(:transfer_requests_attributes) do
      WellHelpers
        .column_order(plate_size)
        .map do |well_name|
          { source_asset: "2-well-#{well_name}", target_asset: "3-well-#{well_name}", submission_id: '2' }
        end
    end

    it 'should create objects' do
      expect_transfer_request_collection_creation

      expect(subject.save!).to eq true
    end
  end
end

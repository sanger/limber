# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# A plate with primer panel has a preview page, but otherwise
# behaves exactly as a normal plate stamp
RSpec.describe LabwareCreators::PlateWithPrimerPanel do
  has_a_working_api
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:parent_uuid) { SecureRandom.uuid }
  let(:plate_size) { 384 }
  let(:requests) do
    Array.new(plate_size) do |i|
      create :gbs_library_request, state: 'started', uuid: "request-#{i}", submission_id: '2'
    end
  end
  let(:parent_plate) do
    create :v2_plate_with_primer_panels,
           barcode_number: '2',
           uuid: parent_uuid,
           size: plate_size,
           outer_requests: requests
  end
  let(:child_plate) { create :v2_plate_with_primer_panels, barcode_number: '3', size: plate_size, uuid: 'child-uuid' }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  before { create :purpose_config, pcr_stage: 'pcr 1', uuid: purpose_uuid }

  it 'has page' do
    expect(described_class.page).to eq 'plate_with_primer_panel'
  end

  # Essentially plate creation behaves as standard. The primer panel information
  # is solely for the user's benefit!
  context 'create plate' do
    let(:plate_creations_attributes) do
      [{ child_purpose_uuid: purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid }]
    end

    before do
      stub_v2_plate(parent_plate, stub_search: false)
      stub_v2_plate(child_plate, stub_search: false)
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

    it 'creates objects' do
      expect_plate_creation
      expect_transfer_request_collection_creation

      expect(subject.save!).to be true
    end
  end
end

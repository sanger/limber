# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

RSpec.describe LabwareCreators::BaitedPlate do
  subject { described_class.new(api, form_attributes) }

  it_behaves_like 'it only allows creation from plates'

  let(:user_uuid) { SecureRandom.uuid }
  let(:purpose_uuid) { SecureRandom.uuid }
  let(:parent_uuid) { 'parent-uuid' }
  let(:requests) do
    Array.new(6) { |i| create :library_request, state: 'started', uuid: "request-#{i}", submission_id: '2' }
  end
  let(:parent_plate) { create :v2_plate, uuid: parent_uuid, outer_requests: requests, barcode_number: 2 }
  let(:child_plate) { create :v2_plate, uuid: 'child-uuid', outer_requests: requests, barcode_number: 3 }

  let(:form_attributes) { { user_uuid:, purpose_uuid:, parent_uuid: } }

  let(:bait_library_layout) { create :bait_library_layout }

  let(:transfer_requests_attributes) do
    WellHelpers.column_order(96)[0, 6].map do |well_name|
      { source_asset: "2-well-#{well_name}", target_asset: "3-well-#{well_name}", submission_id: '2' }
    end
  end

  it 'has page' do
    expect(described_class.page).to eq 'baited_plate'
  end

  context 'create plate' do
    has_a_working_api

    let(:plate_creations_attributes) do
      [{ child_purpose_uuid: purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid }]
    end

    before do
      stub_v2_plate(parent_plate, stub_search: false)
      stub_v2_plate(child_plate, stub_search: false)

      stub_api_v2_post('BaitLibraryLayout')
      stub_api_v2_post('BaitLibraryLayout', [bait_library_layout], method: :preview)
    end

    it 'makes an api call for bait library layout preview' do
      bait_library_layout_preview = {
        'A1' => 'Human all exon 50MB',
        'B1' => 'Human all exon 50MB',
        'C1' => 'Mouse all exon',
        'D1' => 'Mouse all exon'
      }
      expect(subject.bait_library_layout_preview).to eq bait_library_layout_preview
    end

    it 'creates objects' do
      expect_plate_creation
      expect_transfer_request_collection_creation

      expect(subject.create_labware!).to be true
    end
  end
end

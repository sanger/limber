# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_cherrypick_to_bcr_dilution1.csv.erb' do
  context 'with a full plate' do
    has_a_working_api

    let(:source_well_a1) { create(:v2_well, location: 'A1') }
    let(:source_well_b1) { create(:v2_well, location: 'B1') }
    let(:source_labware) { create(:v2_plate, wells: [source_well_a1, source_well_b1], barcode_number: 1) }

    let(:dest_well_a1) { create(:v2_well_with_transfer_requests, location: 'A1', transfer_request_as_target_source_asset: source_well_a1, plate_barcode: '2') }
    let(:dest_well_b1) { create(:v2_well_with_transfer_requests, location: 'B1', transfer_request_as_target_source_asset: source_well_b1, plate_barcode: '2') }
    let(:dest_labware) { create(:v2_plate, wells: [dest_well_a1, dest_well_b1], barcode_number: 2) }

    before do
      create(:fixed_normalisation_purpose_config, uuid: dest_labware.purpose.uuid)
      assign(:plate, dest_labware)
    end

    let(:expected_content) do
      [
        ['Workflow', 'Sample Dilution'],
        ['Source Plate ID', 'Source Plate Well', 'Destination Plate ID', 'Destination Plate Well', 'Sample Vol', 'Dilution Vol'],
        %w[DN1S A1 DN2T B1 2.0 33.0],
        %w[DN1S B1 DN2T A1 2.0 33.0]
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_plate_stamp.csv.erb' do
  context 'when creating a plate stamp csv' do
    has_a_working_api

    let(:source_well_a1) { create(:v2_well, location: 'A1') }
    let(:source_well_b1) { create(:v2_well, location: 'B1') }

    let(:dest_well_a1) do
      create(
        :v2_well_with_transfer_requests,
        location: 'A1',
        transfer_request_as_target_source_asset: source_well_a1,
        plate_barcode: '2'
      )
    end
    let(:dest_well_b1) do
      create(
        :v2_well_with_transfer_requests,
        location: 'B1',
        transfer_request_as_target_source_asset: source_well_b1,
        plate_barcode: '2'
      )
    end
    let(:dest_labware) { create(:v2_plate, wells: [dest_well_a1, dest_well_b1], barcode_number: 2) }
    let(:workflow_name) { 'Test Workflow Name' }

    before do
      assign(:plate, dest_labware)
      assign(:workflow, workflow_name)
    end

    let(:expected_content) do
      [
        ['Workflow', workflow_name],
        ['Source Plate ID', 'Source Plate Well', 'Destination Plate ID', 'Destination Plate Well'],
        %w[DN1S A1 DN2T A1],
        %w[DN1S B1 DN2T B1]
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end

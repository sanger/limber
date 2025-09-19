# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'tube_racks/tube_racks_exports/tube_rack_concentrations_nm.csv.erb' do
  context 'with a filled rack' do
    let(:qc_result_options) { { value: 1.5, key: 'molarity', units: 'nM' } }

    let(:labware_uuid) { SecureRandom.uuid }

    let(:tube1_uuid) { SecureRandom.uuid }
    let(:tube2_uuid) { SecureRandom.uuid }
    let(:tube3_uuid) { SecureRandom.uuid }

    let!(:tube1) { create :tube, uuid: tube1_uuid, barcode_number: 1, state: 'pending' }
    let!(:tube2) { create :tube, uuid: tube2_uuid, barcode_number: 2, state: 'pending' }
    let!(:tube3) { create :tube, uuid: tube3_uuid, barcode_number: 3, state: 'passed' }

    # NB. deliberately mixing up the tubes to check they are sorted in the file output
    let(:tubes) { { 'B1' => tube1, 'A1' => tube2, 'C1' => tube3 } }

    # NB. factory sets up the racked tubes given the tubes hash above
    let!(:tube_rack1) { create :tube_rack, barcode_number: 4, uuid: labware_uuid, tubes: tubes }

    let(:tube_rack_barcode) { tube_rack1.labware_barcode.human }

    before do
      tube1.receptacle.qc_results << create(:qc_result, qc_result_options)
      tube2.receptacle.qc_results << create(:qc_result, qc_result_options)
      tube3.receptacle.qc_results << create(:qc_result, qc_result_options)

      assign(:tube_rack, tube_rack1)
    end

    # NB. tubes ordered by tube rack coordinate
    let(:expected_content) do
      [
        ['Tube Rack Barcode', tube_rack_barcode],
        [],
        ['Tube Barcode', 'Rack Coordinate', 'Concentration (nM)', 'Tube Passed?'],
        [tube2.human_barcode, 'A1', '1.5', '0'],
        [tube1.human_barcode, 'B1', '1.5', '0'],
        [tube3.human_barcode, 'C1', '1.5', '1']
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end

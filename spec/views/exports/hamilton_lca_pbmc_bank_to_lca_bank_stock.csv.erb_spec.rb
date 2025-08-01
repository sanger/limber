# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lca_pbmc_bank_to_lca_bank_stock.csv.erb' do
  context 'when creating a hamilton driver file csv' do
    # samples
    let(:sample1_uuid) { SecureRandom.uuid }
    let(:sample2_uuid) { SecureRandom.uuid }

    let(:sample1) { create(:v2_sample, name: 'Sample1', uuid: sample1_uuid) }
    let(:sample2) { create(:v2_sample, name: 'Sample2', uuid: sample2_uuid) }

    # ancestor vac tubes
    let(:vac_aliquot1) { create(:v2_aliquot, sample: sample1) }
    let(:vac_aliquot2) { create(:v2_aliquot, sample: sample2) }

    let(:ancestor_vac_tube_1) { create(:v2_tube, barcode_number: 1, aliquots: [vac_aliquot1]) }
    let(:ancestor_vac_tube_2) { create(:v2_tube, barcode_number: 2, aliquots: [vac_aliquot2]) }

    # ancestor tubes hash
    let(:ancestor_tubes) { { sample1_uuid => ancestor_vac_tube_1, sample2_uuid => ancestor_vac_tube_2 } }

    # source plate
    let(:source_aliquot1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot2) { create(:v2_aliquot, sample: sample2) }

    let(:source_well_a1) do
      create(:v2_well, location: 'A1', aliquots: [source_aliquot1], downstream_tubes: [dest_tube1])
    end
    let(:source_well_b1) do
      create(:v2_well, location: 'B1', aliquots: [source_aliquot2], downstream_tubes: [dest_tube2])
    end

    let(:source_labware) { create(:v2_plate, wells: [source_well_a1, source_well_b1], barcode_number: 3) }

    # destination tube
    let(:dest_aliquot1) { create(:v2_aliquot, sample: sample1) }
    let(:dest_aliquot2) { create(:v2_aliquot, sample: sample2) }
    let(:dest_tube1) { create(:v2_tube, barcode_number: 4, aliquots: [dest_aliquot1], name: 'DESTTUBE:A1') }
    let(:dest_tube2) { create(:v2_tube, barcode_number: 5, aliquots: [dest_aliquot2], name: 'DESTTUBE:B1') }

    # workflow
    let(:workflow_name) { 'Test Workflow Name' }

    before do
      assign(:ancestor_tubes, ancestor_tubes)
      assign(:plate, source_labware)
      assign(:workflow, workflow_name)
    end

    let(:expected_content) do
      [
        ['Workflow', workflow_name],
        [],
        [
          'Source Plate ID',
          'Source Plate Well',
          'Destination Tube ID',
          'Destination Tube Position',
          'Sample Vac Tube ID',
          'Sample Name'
        ],
        %w[DN3U A1 NT4R A1 NT1O Sample1],
        %w[DN3U B1 NT5S B1 NT2P Sample2]
      ]
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end

    context 'when transfers are not done yet' do
      let(:source_well_a1) { create(:v2_well, location: 'A1', aliquots: [source_aliquot1], downstream_tubes: []) }
      let(:source_well_b1) { create(:v2_well, location: 'B1', aliquots: [source_aliquot2], downstream_tubes: []) }

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Source Plate ID',
            'Source Plate Well',
            'Destination Tube ID',
            'Destination Tube Position',
            'Sample Vac Tube ID',
            'Sample Name'
          ]
        ]
      end

      it 'does not show sample rows' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end

    context 'when destination has no aliquots' do
      let(:dest_tube1) { create(:v2_tube, barcode_number: 4, aliquots: [], name: 'DESTTUBE:A1') }
      let(:dest_tube2) { create(:v2_tube, barcode_number: 5, aliquots: [], name: 'DESTTUBE:B1') }

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Source Plate ID',
            'Source Plate Well',
            'Destination Tube ID',
            'Destination Tube Position',
            'Sample Vac Tube ID',
            'Sample Name'
          ]
        ]
      end

      it 'does not show sample rows' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end
  end
end

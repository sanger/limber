# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'tube_racks/tube_racks_exports/hamilton_lrc_pbmc_bank_to_lrc_bank_seq_and_spare.csv.erb' do
  include FeatureHelpers

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

    # source aliquots
    let(:source_aliquot1_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot2_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot3_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot1_s2) { create(:v2_aliquot, sample: sample2) }
    let(:source_aliquot2_s2) { create(:v2_aliquot, sample: sample2) }
    let(:source_aliquot3_s2) { create(:v2_aliquot, sample: sample2) }

    # source wells
    let(:source_well_a1) do
      create(:v2_well, location: 'A1', aliquots: [source_aliquot1_s1], downstream_tubes: [dest_tube1])
    end
    let(:source_well_a2) do
      create(:v2_well, location: 'A2', aliquots: [source_aliquot2_s1], downstream_tubes: [dest_tube2])
    end
    let(:source_well_a3) do
      create(:v2_well, location: 'A3', aliquots: [source_aliquot3_s1], downstream_tubes: [dest_tube3])
    end

    let(:source_well_b1) do
      create(:v2_well, location: 'B1', aliquots: [source_aliquot1_s2], downstream_tubes: [dest_tube4])
    end
    let(:source_well_b2) do
      create(:v2_well, location: 'B2', aliquots: [source_aliquot2_s2], downstream_tubes: [dest_tube5])
    end
    let(:source_well_b3) do
      create(:v2_well, location: 'B3', aliquots: [source_aliquot3_s2], downstream_tubes: [dest_tube6])
    end

    # source plate
    let(:source_labware) do
      create(
        :v2_plate,
        wells: [source_well_a1, source_well_a2, source_well_a3, source_well_b1, source_well_b2, source_well_b3],
        barcode_number: 3
      )
    end

    # destination aliquots
    let(:dest_aliquot1) { create(:v2_aliquot, sample: sample1) }
    let(:dest_aliquot2) { create(:v2_aliquot, sample: sample1) }
    let(:dest_aliquot3) { create(:v2_aliquot, sample: sample1) }
    let(:dest_aliquot4) { create(:v2_aliquot, sample: sample2) }
    let(:dest_aliquot5) { create(:v2_aliquot, sample: sample2) }
    let(:dest_aliquot6) { create(:v2_aliquot, sample: sample2) }

    # destination tubes
    let(:dest_tube1) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 4, aliquots: [dest_aliquot1], name: 'SEQ:NT1O:A1')
    end
    let(:dest_tube2) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 5, aliquots: [dest_aliquot2], name: 'SPR:NT1O:A1')
    end
    let(:dest_tube3) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 6, aliquots: [dest_aliquot3], name: 'SPR:NT1O:B1')
    end
    let(:dest_tube4) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 7, aliquots: [dest_aliquot4], name: 'SEQ:NT2P:B1')
    end
    let(:dest_tube5) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 8, aliquots: [dest_aliquot5], name: 'SPR:NT2P:C1')
    end
    let(:dest_tube6) do
      create(:v2_tube, barcode_prefix: 'FX', barcode_number: 9, aliquots: [dest_aliquot6], name: 'SPR:NT2P:D1')
    end

    # Tube racks
    let(:seq_tube_rack) { create(:tube_rack, tubes: { A1: dest_tube1, B1: dest_tube4 }, parents: [source_labware]) }
    let(:spr_tube_rack) do
      create(
        :tube_rack,
        tubes: {
          A1: dest_tube2,
          B1: dest_tube3,
          C1: dest_tube5,
          D1: dest_tube6
        },
        parents: [source_labware]
      )
    end

    # workflow
    let(:workflow_name) { 'Test Workflow Name' }

    # expected file content
    let(:expected_content) do
      [
        ['Workflow', workflow_name],
        [],
        [
          'Source Plate ID',
          'Source Plate Well',
          'Destination Rack',
          'Purpose',
          'Destination Tube ID',
          'Destination Tube Position',
          'Sample Vac Tube ID',
          'Sample Name'
        ],
        ['DN3U', 'A1', seq_tube_rack.human_barcode, 'Sequencing', 'FX4B', 'A1', 'NT1O', 'Sample1'],
        ['DN3U', 'B1', seq_tube_rack.human_barcode, 'Sequencing', 'FX7E', 'B1', 'NT2P', 'Sample2'],
        ['DN3U', 'A2', spr_tube_rack.human_barcode, 'Contingency', 'FX5C', 'A1', 'NT1O', 'Sample1'],
        ['DN3U', 'B2', spr_tube_rack.human_barcode, 'Contingency', 'FX8F', 'C1', 'NT2P', 'Sample2'],
        ['DN3U', 'A3', spr_tube_rack.human_barcode, 'Contingency', 'FX6D', 'B1', 'NT1O', 'Sample1'],
        ['DN3U', 'B3', spr_tube_rack.human_barcode, 'Contingency', 'FX9G', 'D1', 'NT2P', 'Sample2']
      ]
    end

    before do
      assign(:ancestor_tubes, ancestor_tubes)
      assign(:tube_rack, seq_tube_rack)
      assign(:workflow, workflow_name)

      allow(source_labware).to receive(:children).and_return([seq_tube_rack, spr_tube_rack])

      # stub the v2 tube rack lookup
      tube_racks = [seq_tube_rack, spr_tube_rack]
      tube_racks.each do |tube_rack|
        allow(Sequencescape::Api::V2).to receive(:tube_rack_with_custom_includes).with(
          'racked_tubes.tube',
          nil,
          barcode: tube_rack.barcode.machine
        ).and_return(tube_rack)
      end

      # stub the v2 plate lookup
      allow(Sequencescape::Api::V2).to receive(:plate_with_custom_includes).with(
        %w[wells.downstream_tubes wells.transfer_requests_as_source.target_asset],
        barcode: source_labware.barcode.human
      ).and_return(source_labware)
    end

    it 'renders the expected content' do
      expect(CSV.parse(render)).to eq(expected_content)
    end

    context 'when transfers are not done yet' do
      # source wells
      let(:source_well_a1) { create(:v2_well, location: 'A1', aliquots: [source_aliquot1_s1], downstream_tubes: []) }
      let(:source_well_a2) { create(:v2_well, location: 'A2', aliquots: [source_aliquot2_s1], downstream_tubes: []) }
      let(:source_well_a3) { create(:v2_well, location: 'A3', aliquots: [source_aliquot3_s1], downstream_tubes: []) }

      let(:source_well_b1) { create(:v2_well, location: 'B1', aliquots: [source_aliquot1_s2], downstream_tubes: []) }
      let(:source_well_b2) { create(:v2_well, location: 'B2', aliquots: [source_aliquot2_s2], downstream_tubes: []) }
      let(:source_well_b3) { create(:v2_well, location: 'B3', aliquots: [source_aliquot3_s2], downstream_tubes: []) }

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Source Plate ID',
            'Source Plate Well',
            'Destination Rack',
            'Purpose',
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

    context 'when destination tubes are not in the tube_rack' do
      # Setup the tube racks to have different tubes that the ones from the downstream tubes
      let(:seq_tube_rack) do
        create(
          :tube_rack,
          tubes: {
            A1: create(:v2_tube, barcode_prefix: 'FX', barcode_number: 7),
            B1: create(:v2_tube, barcode_prefix: 'FX', barcode_number: 7)
          },
          parents: [source_labware]
        )
      end

      let(:spr_tube_rack) do
        create(
          :tube_rack,
          tubes: {
            A1: create(:v2_tube, barcode_prefix: 'FX', barcode_number: 7),
            B1: create(:v2_tube, barcode_prefix: 'FX', barcode_number: 7)
          },
          parents: [source_labware]
        )
      end

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Source Plate ID',
            'Source Plate Well',
            'Destination Rack',
            'Purpose',
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

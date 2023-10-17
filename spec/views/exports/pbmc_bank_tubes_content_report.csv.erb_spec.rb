# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/pbmc_bank_tubes_content_report.csv.erb', type: :view do
  include FeatureHelpers

  context 'when creating a pbmc bank tubes content report csv' do
    has_a_working_api

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

    # metadata for destination tubes
    let(:dest_tube1_metadata) { { 'tube_rack_barcode' => 'TR00000001', 'tube_rack_position' => 'A1' } }
    let(:dest_tube2_metadata) { { 'tube_rack_barcode' => 'TR00000002', 'tube_rack_position' => 'A1' } }
    let(:dest_tube3_metadata) { { 'tube_rack_barcode' => 'TR00000002', 'tube_rack_position' => 'B1' } }
    let(:dest_tube4_metadata) { { 'tube_rack_barcode' => 'TR00000001', 'tube_rack_position' => 'B1' } }
    let(:dest_tube5_metadata) { { 'tube_rack_barcode' => 'TR00000002', 'tube_rack_position' => 'C1' } }
    let(:dest_tube6_metadata) { { 'tube_rack_barcode' => 'TR00000002', 'tube_rack_position' => 'D1' } }

    # custom metadata collections for destination tubes
    let(:dest_tube1_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube1_metadata) }
    let(:dest_tube2_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube2_metadata) }
    let(:dest_tube3_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube3_metadata) }
    let(:dest_tube4_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube4_metadata) }
    let(:dest_tube5_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube5_metadata) }
    let(:dest_tube6_custom_metadata) { create(:custom_metadatum_collection, metadata: dest_tube6_metadata) }

    # destination tube uuids
    let(:dest_tube1_uuid) { SecureRandom.uuid }
    let(:dest_tube2_uuid) { SecureRandom.uuid }
    let(:dest_tube3_uuid) { SecureRandom.uuid }
    let(:dest_tube4_uuid) { SecureRandom.uuid }
    let(:dest_tube5_uuid) { SecureRandom.uuid }
    let(:dest_tube6_uuid) { SecureRandom.uuid }

    # destination tubes
    let(:dest_tube1) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube1_uuid,
        barcode_prefix: 'FX',
        barcode_number: 4,
        aliquots: [dest_aliquot1],
        name: 'SEQ:NT1O:A1',
        custom_metadatum_collection: dest_tube1_custom_metadata
      )
    end
    let(:dest_tube2) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube2_uuid,
        barcode_prefix: 'FX',
        barcode_number: 5,
        aliquots: [dest_aliquot2],
        name: 'SPR:NT1O:A1',
        custom_metadatum_collection: dest_tube2_custom_metadata
      )
    end
    let(:dest_tube3) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube3_uuid,
        barcode_prefix: 'FX',
        barcode_number: 6,
        aliquots: [dest_aliquot3],
        name: 'SPR:NT1O:B1',
        custom_metadatum_collection: dest_tube3_custom_metadata
      )
    end
    let(:dest_tube4) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube4_uuid,
        barcode_prefix: 'FX',
        barcode_number: 7,
        aliquots: [dest_aliquot4],
        name: 'SEQ:NT2P:B1',
        custom_metadatum_collection: dest_tube4_custom_metadata
      )
    end
    let(:dest_tube5) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube5_uuid,
        barcode_prefix: 'FX',
        barcode_number: 8,
        aliquots: [dest_aliquot5],
        name: 'SPR:NT2P:C1',
        custom_metadatum_collection: dest_tube5_custom_metadata
      )
    end
    let(:dest_tube6) do
      create(
        :v2_tube_with_metadata,
        uuid: dest_tube6_uuid,
        barcode_prefix: 'FX',
        barcode_number: 9,
        aliquots: [dest_aliquot6],
        name: 'SPR:NT2P:D1',
        custom_metadatum_collection: dest_tube6_custom_metadata
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
        %w[DN3U A1 TR00000001 Sequencing FX4B A1 NT1O Sample1],
        %w[DN3U B1 TR00000001 Sequencing FX7E B1 NT2P Sample2],
        %w[DN3U A2 TR00000002 Contingency FX5C A1 NT1O Sample1],
        %w[DN3U B2 TR00000002 Contingency FX8F C1 NT2P Sample2],
        %w[DN3U A3 TR00000002 Contingency FX6D B1 NT1O Sample1],
        %w[DN3U B3 TR00000002 Contingency FX9G D1 NT2P Sample2]
      ]
    end

    before do
      assign(:ancestor_tubes, ancestor_tubes)
      assign(:plate, source_labware)
      assign(:workflow, workflow_name)

      # stub the v2 child tube lookups
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube1.barcode.machine)
        .and_return(dest_tube1)
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube2.barcode.machine)
        .and_return(dest_tube2)
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube3.barcode.machine)
        .and_return(dest_tube3)
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube4.barcode.machine)
        .and_return(dest_tube4)
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube5.barcode.machine)
        .and_return(dest_tube5)
      allow(Sequencescape::Api::V2).to receive(:tube_with_custom_includes)
        .with('custom_metadatum_collection', nil, barcode: dest_tube6.barcode.machine)
        .and_return(dest_tube6)
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

    context 'when destination tubes have no custom metadatum collection' do
      let(:dest_tube1) do
        create(
          :v2_tube,
          uuid: dest_tube1_uuid,
          barcode_prefix: 'FX',
          barcode_number: 4,
          aliquots: [dest_aliquot1],
          name: 'SEQ:NT1O:A1',
          custom_metadatum_collection: nil
        )
      end
      let(:dest_tube2) do
        create(
          :v2_tube,
          uuid: dest_tube2_uuid,
          barcode_prefix: 'FX',
          barcode_number: 5,
          aliquots: [dest_aliquot2],
          name: 'SPR:NT1O:A1',
          custom_metadatum_collection: nil
        )
      end
      let(:dest_tube3) do
        create(
          :v2_tube,
          uuid: dest_tube3_uuid,
          barcode_prefix: 'FX',
          barcode_number: 6,
          aliquots: [dest_aliquot3],
          name: 'SPR:NT1O:B1',
          custom_metadatum_collection: nil
        )
      end
      let(:dest_tube4) do
        create(
          :v2_tube,
          uuid: dest_tube4_uuid,
          barcode_prefix: 'FX',
          barcode_number: 7,
          aliquots: [dest_aliquot4],
          name: 'SEQ:NT2P:B1',
          custom_metadatum_collection: nil
        )
      end
      let(:dest_tube5) do
        create(
          :v2_tube,
          uuid: dest_tube5_uuid,
          barcode_prefix: 'FX',
          barcode_number: 8,
          aliquots: [dest_aliquot5],
          name: 'SPR:NT2P:C1',
          custom_metadatum_collection: nil
        )
      end
      let(:dest_tube6) do
        create(
          :v2_tube,
          uuid: dest_tube6_uuid,
          barcode_prefix: 'FX',
          barcode_number: 9,
          aliquots: [dest_aliquot6],
          name: 'SPR:NT2P:D1',
          custom_metadatum_collection: nil
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

    context 'when destination tubes have inappropriate metadata' do
      let(:useless_custom_metadata) { create(:custom_metadatum_collection, metadata: { 'somekey' => 'somevalue' }) }

      let(:dest_tube1) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube1_uuid,
          barcode_prefix: 'FX',
          barcode_number: 4,
          aliquots: [dest_aliquot1],
          name: 'SEQ:NT1O:A1',
          custom_metadatum_collection: useless_custom_metadata
        )
      end
      let(:dest_tube2) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube2_uuid,
          barcode_prefix: 'FX',
          barcode_number: 5,
          aliquots: [dest_aliquot2],
          name: 'SPR:NT1O:A1',
          custom_metadatum_collection: useless_custom_metadata
        )
      end
      let(:dest_tube3) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube3_uuid,
          barcode_prefix: 'FX',
          barcode_number: 6,
          aliquots: [dest_aliquot3],
          name: 'SPR:NT1O:B1',
          custom_metadatum_collection: useless_custom_metadata
        )
      end
      let(:dest_tube4) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube4_uuid,
          barcode_prefix: 'FX',
          barcode_number: 7,
          aliquots: [dest_aliquot4],
          name: 'SEQ:NT2P:B1',
          custom_metadatum_collection: useless_custom_metadata
        )
      end
      let(:dest_tube5) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube5_uuid,
          barcode_prefix: 'FX',
          barcode_number: 8,
          aliquots: [dest_aliquot5],
          name: 'SPR:NT2P:C1',
          custom_metadatum_collection: useless_custom_metadata
        )
      end
      let(:dest_tube6) do
        create(
          :v2_tube_with_metadata,
          uuid: dest_tube6_uuid,
          barcode_prefix: 'FX',
          barcode_number: 9,
          aliquots: [dest_aliquot6],
          name: 'SPR:NT2P:D1',
          custom_metadatum_collection: useless_custom_metadata
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

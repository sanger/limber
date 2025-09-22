# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/pbmc_bank_tubes_content_report.csv.erb', type: :view do
  include FeatureHelpers

  context 'when creating a pbmc bank tubes content report csv' do
    # study
    let(:study_name) { 'Report Study' }
    let(:study) { create(:study, name: study_name) }

    # samples

    let(:sample_metadata1) { create(:sample_metadata, donor_id: 'Donor1') }
    let(:sample_metadata2) { create(:sample_metadata) }

    let(:sample1_uuid) { SecureRandom.uuid }
    let(:sample2_uuid) { SecureRandom.uuid }

    let(:sample1) { create(:sample, name: 'Sample1', uuid: sample1_uuid, sample_metadata: sample_metadata1) }
    let(:sample2) { create(:sample, name: 'Sample2', uuid: sample2_uuid, sample_metadata: sample_metadata2) }

    # ancestor vac tubes
    let(:vac_aliquot1) { create(:aliquot, sample: sample1) }
    let(:vac_aliquot2) { create(:aliquot, sample: sample2) }

    let(:ancestor_vac_tube_1) { create(:tube, barcode_number: 1, aliquots: [vac_aliquot1]) }
    let(:ancestor_vac_tube_2) { create(:tube, barcode_number: 2, aliquots: [vac_aliquot2]) }

    # ancestor tubes hash
    let(:ancestor_tubes) { { sample1_uuid => ancestor_vac_tube_1, sample2_uuid => ancestor_vac_tube_2 } }

    # source aliquots
    let(:src_aliquot1_s1) { create(:aliquot, sample: sample1, study: study) }
    let(:src_aliquot2_s1) { create(:aliquot, sample: sample1, study: study) }
    let(:src_aliquot3_s1) { create(:aliquot, sample: sample1, study: study) }
    let(:src_aliquot1_s2) { create(:aliquot, sample: sample2, study: study) }
    let(:src_aliquot2_s2) { create(:aliquot, sample: sample2, study: study) }
    let(:src_aliquot3_s2) { create(:aliquot, sample: sample2, study: study) }

    # qc results
    let(:total_cell_count_qc) { create(:qc_result, key: 'total_cell_count', value: '20000', units: 'cells/ml') }
    let(:viability_qc) { create(:qc_result, key: 'viability', value: '75', units: '%') }
    let(:qc_results) { [total_cell_count_qc, viability_qc] }

    # source wells
    let(:source_well_attributes) do
      [
        { location: 'A1', aliquots: [src_aliquot1_s1], downstream_tubes: [dest_tube1], qc_results: qc_results },
        { location: 'A2', aliquots: [src_aliquot2_s1], downstream_tubes: [dest_tube2], qc_results: qc_results },
        { location: 'A3', aliquots: [src_aliquot3_s1], downstream_tubes: [dest_tube3], qc_results: qc_results },
        { location: 'B1', aliquots: [src_aliquot1_s2], downstream_tubes: [dest_tube4], qc_results: qc_results },
        { location: 'B2', aliquots: [src_aliquot2_s2], downstream_tubes: [dest_tube5], qc_results: qc_results },
        { location: 'B3', aliquots: [src_aliquot3_s2], downstream_tubes: [dest_tube6], qc_results: qc_results }
      ]
    end

    let(:src_well_a1) { create(:well, source_well_attributes[0]) }
    let(:src_well_a2) { create(:well, source_well_attributes[1]) }
    let(:src_well_a3) { create(:well, source_well_attributes[2]) }
    let(:src_well_b1) { create(:well, source_well_attributes[3]) }
    let(:src_well_b2) { create(:well, source_well_attributes[4]) }
    let(:src_well_b3) { create(:well, source_well_attributes[5]) }

    # source plate
    let(:src_labware) do
      create(
        :plate,
        wells: [src_well_a1, src_well_a2, src_well_a3, src_well_b1, src_well_b2, src_well_b3],
        barcode_number: 3
      )
    end

    # destination aliquots
    let(:dest_aliquot1) { create(:aliquot, sample: sample1) }
    let(:dest_aliquot2) { create(:aliquot, sample: sample1) }
    let(:dest_aliquot3) { create(:aliquot, sample: sample1) }
    let(:dest_aliquot4) { create(:aliquot, sample: sample2) }
    let(:dest_aliquot5) { create(:aliquot, sample: sample2) }
    let(:dest_aliquot6) { create(:aliquot, sample: sample2) }

    # destination tube uuids
    let(:dest_tube1_uuid) { SecureRandom.uuid }
    let(:dest_tube2_uuid) { SecureRandom.uuid }
    let(:dest_tube3_uuid) { SecureRandom.uuid }
    let(:dest_tube4_uuid) { SecureRandom.uuid }
    let(:dest_tube5_uuid) { SecureRandom.uuid }
    let(:dest_tube6_uuid) { SecureRandom.uuid }

    # destination purposes
    let(:lrc_bank_seq) { create(:purpose, name: 'LRC Bank Seq') }
    let(:lrc_bank_spare) { create(:purpose, name: 'LRC Bank Spare') }

    # destination tubes
    let(:dest_tube1) do
      create(
        :tube,
        purpose: lrc_bank_seq,
        uuid: dest_tube1_uuid,
        barcode_prefix: 'FX',
        barcode_number: 4,
        aliquots: [dest_aliquot1],
        name: 'SEQ:NT1O:A1'
      )
    end
    let(:dest_tube2) do
      create(
        :tube,
        purpose: lrc_bank_spare,
        uuid: dest_tube2_uuid,
        barcode_prefix: 'FX',
        barcode_number: 5,
        aliquots: [dest_aliquot2],
        name: 'SPR:NT1O:A1'
      )
    end
    let(:dest_tube3) do
      create(
        :tube,
        purpose: lrc_bank_spare,
        uuid: dest_tube3_uuid,
        barcode_prefix: 'FX',
        barcode_number: 6,
        aliquots: [dest_aliquot3],
        name: 'SPR:NT1O:B1'
      )
    end
    let(:dest_tube4) do
      create(
        :tube,
        purpose: lrc_bank_seq,
        uuid: dest_tube4_uuid,
        barcode_prefix: 'FX',
        barcode_number: 7,
        aliquots: [dest_aliquot4],
        name: 'SEQ:NT2P:B1'
      )
    end
    let(:dest_tube5) do
      create(
        :tube,
        purpose: lrc_bank_spare,
        uuid: dest_tube5_uuid,
        barcode_prefix: 'FX',
        barcode_number: 8,
        aliquots: [dest_aliquot5],
        name: 'SPR:NT2P:C1'
      )
    end
    let(:dest_tube6) do
      create(
        :tube,
        purpose: lrc_bank_spare,
        uuid: dest_tube6_uuid,
        barcode_prefix: 'FX',
        barcode_number: 9,
        aliquots: [dest_aliquot6],
        name: 'SPR:NT2P:D1'
      )
    end

    # workflow
    let(:workflow_name) { 'Test Workflow Name' }

    # expected file content
    let(:created_at) { '2017-06-29 09:31:59 +0100' }
    let(:expected_content) do
      [
        ['Workflow', workflow_name],
        [],
        [
          'Well name',
          'Donor ID',
          'Stock barcode',
          'FluidX barcode',
          'Extraction and freeze date',
          'Sequencing or contingency',
          'Total cell count (cells/ml)',
          'Viability (%)',
          'Volume (µl)',
          'Study name',
          'Collection site'
        ],
        ['DN1S:A1', 'Donor1', 'NT1O', 'FX4B', created_at, 'Sequencing', '20000', '75', '125', study_name, 'Sanger'],
        ['DN1S:B1', '', 'NT2P', 'FX7E', created_at, 'Sequencing', '20000', '75', '125', study_name, 'Sanger'],
        ['DN1S:A2', 'Donor1', 'NT1O', 'FX5C', created_at, 'Contingency', '20000', '75', '125', study_name, 'Sanger'],
        ['DN1S:B2', '', 'NT2P', 'FX8F', created_at, 'Contingency', '20000', '75', '125', study_name, 'Sanger'],
        ['DN1S:A3', 'Donor1', 'NT1O', 'FX6D', created_at, 'Contingency', '20000', '75', '125', study_name, 'Sanger'],
        ['DN1S:B3', '', 'NT2P', 'FX9G', created_at, 'Contingency', '20000', '75', '125', study_name, 'Sanger']
      ]
    end

    before do
      assign(:ancestor_tubes, ancestor_tubes)
      assign(:plate, src_labware)
      assign(:workflow, workflow_name)
    end

    # rubocop:disable RSpec/IteratedExpectation
    it 'renders the expected content row by row' do
      CSV.parse(render).each { |row| expect(row).to eq(expected_content.shift) }
    end
    # rubocop:enable RSpec/IteratedExpectation

    context 'when some data is missing' do
      # qc results, no viability_qc
      let(:total_cell_count_qc) { create(:qc_result, key: 'total_cell_count', value: nil, units: 'cells/ml') }
      let(:qc_results) { [total_cell_count_qc] }

      # expected file content
      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Well name',
            'Donor ID',
            'Stock barcode',
            'FluidX barcode',
            'Extraction and freeze date',
            'Sequencing or contingency',
            'Total cell count (cells/ml)',
            'Viability (%)',
            'Volume (µl)',
            'Study name',
            'Collection site'
          ],
          ['DN1S:A1', 'Donor1', 'NT1O', 'FX4B', created_at, 'Sequencing', '', '', '125', study_name, 'Sanger'],
          ['DN1S:B1', '', 'NT2P', 'FX7E', created_at, 'Sequencing', '', '', '125', study_name, 'Sanger'],
          ['DN1S:A2', 'Donor1', 'NT1O', 'FX5C', created_at, 'Contingency', '', '', '125', study_name, 'Sanger'],
          ['DN1S:B2', '', 'NT2P', 'FX8F', created_at, 'Contingency', '', '', '125', study_name, 'Sanger'],
          ['DN1S:A3', 'Donor1', 'NT1O', 'FX6D', created_at, 'Contingency', '', '', '125', study_name, 'Sanger'],
          ['DN1S:B3', '', 'NT2P', 'FX9G', created_at, 'Contingency', '', '', '125', study_name, 'Sanger']
        ]
      end

      # rubocop:disable RSpec/IteratedExpectation
      it 'shows blanks in the missing columns, row by row' do
        CSV.parse(render).each { |row| expect(row).to eq(expected_content.shift) }
      end
      # rubocop:enable RSpec/IteratedExpectation
    end

    context 'when transfers are not done yet' do
      # source wells
      let(:src_well_a1) { create(:well, location: 'A1', aliquots: [src_aliquot1_s1], downstream_tubes: []) }
      let(:src_well_a2) { create(:well, location: 'A2', aliquots: [src_aliquot2_s1], downstream_tubes: []) }
      let(:src_well_a3) { create(:well, location: 'A3', aliquots: [src_aliquot3_s1], downstream_tubes: []) }

      let(:src_well_b1) { create(:well, location: 'B1', aliquots: [src_aliquot1_s2], downstream_tubes: []) }
      let(:src_well_b2) { create(:well, location: 'B2', aliquots: [src_aliquot2_s2], downstream_tubes: []) }
      let(:src_well_b3) { create(:well, location: 'B3', aliquots: [src_aliquot3_s2], downstream_tubes: []) }

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Well name',
            'Donor ID',
            'Stock barcode',
            'FluidX barcode',
            'Extraction and freeze date',
            'Sequencing or contingency',
            'Total cell count (cells/ml)',
            'Viability (%)',
            'Volume (µl)',
            'Study name',
            'Collection site'
          ]
        ]
      end

      it 'does not show sample rows' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end

    context 'when some downstream tubes are not in passed state' do
      let(:failed_tube) do
        create(
          :tube,
          purpose: lrc_bank_seq,
          uuid: SecureRandom.uuid,
          barcode_prefix: 'FX',
          barcode_number: 99,
          aliquots: [dest_aliquot1],
          name: 'SEQ:FAILED',
          state: 'failed'
        )
      end

      let(:source_well_attributes) do
        [
          { location: 'A1', aliquots: [src_aliquot1_s1], downstream_tubes: [dest_tube1],
            qc_results: qc_results },
          { location: 'A2', aliquots: [src_aliquot2_s1], downstream_tubes: [failed_tube],
            qc_results: qc_results }
        ]
      end

      let(:src_well_a1) { create(:well, source_well_attributes[0]) }
      let(:src_labware) { create(:plate, wells: [src_well_a1], barcode_number: 3) }

      let(:expected_content) do
        [
          ['Workflow', workflow_name],
          [],
          [
            'Well name',
            'Donor ID',
            'Stock barcode',
            'FluidX barcode',
            'Extraction and freeze date',
            'Sequencing or contingency',
            'Total cell count (cells/ml)',
            'Viability (%)',
            'Volume (µl)',
            'Study name',
            'Collection site'
          ],
          # Only the passed tube should appear, not the failed one
          ['DN1S:A1', 'Donor1', 'NT1O', 'FX4B', created_at, 'Sequencing', '20000', '75', '125', study_name, 'Sanger']
        ]
      end

      before do
        assign(:ancestor_tubes, ancestor_tubes)
        assign(:plate, src_labware)
        assign(:workflow, workflow_name)
      end

      it 'renders only tubes in passed state' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end
  end
end

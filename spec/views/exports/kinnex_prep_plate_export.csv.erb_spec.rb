# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/kinnex_prep_plate_export.csv.erb' do
  include FeatureHelpers

  context 'when creating a kinnex prep plate export csv' do
    # samples
    let(:sample1_uuid) { SecureRandom.uuid }
    let(:sample2_uuid) { SecureRandom.uuid }

    let(:sample1) { create(:v2_sample, name: 'Sample1', uuid: sample1_uuid) }
    let(:sample2) { create(:v2_sample, name: 'Sample2', uuid: sample2_uuid) }

    # source aliquots
    let(:source_aliquot1_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot2_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot3_s1) { create(:v2_aliquot, sample: sample1) }
    let(:source_aliquot1_s2) { create(:v2_aliquot, sample: sample2) }
    let(:source_aliquot2_s2) { create(:v2_aliquot, sample: sample2) }
    let(:source_aliquot3_s2) { create(:v2_aliquot, sample: sample2) }

    # source wells
    let(:source_well_a1) do
      # Multiple downstream tubes as in Kinnex Prep
      create(:v2_well, location: 'A1', aliquots: [source_aliquot1_s1], downstream_tubes: [dest_tube1, dest_tube7])
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
    let(:dest_aliquot7) { create(:v2_aliquot, sample: sample2) }

    # destination tube uuids
    let(:dest_tube1_uuid) { SecureRandom.uuid }
    let(:dest_tube2_uuid) { SecureRandom.uuid }
    let(:dest_tube3_uuid) { SecureRandom.uuid }
    let(:dest_tube4_uuid) { SecureRandom.uuid }
    let(:dest_tube5_uuid) { SecureRandom.uuid }
    let(:dest_tube6_uuid) { SecureRandom.uuid }
    let(:dest_tube7_uuid) { SecureRandom.uuid }

    # destination tubes
    let(:dest_tube1) { create(:v2_tube, uuid: dest_tube1_uuid, aliquots: [dest_aliquot1], name: 'SEQ:NT1O:A1') }
    let(:dest_tube2) { create(:v2_tube, uuid: dest_tube2_uuid, aliquots: [dest_aliquot2], name: 'SPR:NT1O:A1') }
    let(:dest_tube3) { create(:v2_tube, uuid: dest_tube3_uuid, aliquots: [dest_aliquot3], name: 'SPR:NT1O:B1') }
    let(:dest_tube4) { create(:v2_tube, uuid: dest_tube4_uuid, aliquots: [dest_aliquot4], name: 'SEQ:NT2P:B1') }
    let(:dest_tube5) { create(:v2_tube, uuid: dest_tube5_uuid, aliquots: [dest_aliquot5], name: 'SPR:NT2P:C1') }
    let(:dest_tube6) { create(:v2_tube, uuid: dest_tube6_uuid, aliquots: [dest_aliquot6], name: 'SPR:NT2P:D1') }
    let(:dest_tube7) { create(:v2_tube, uuid: dest_tube7_uuid, aliquots: [dest_aliquot7], name: 'SPR:NT2P:E1') }

    # expected file content
    let(:expected_content) do
      [
        ['Source plate barcode', 'Source well position', 'Destination tube barcode'],
        ['DN3U', 'A1', dest_tube1.barcode.human],
        ['DN3U', 'A1', dest_tube7.barcode.human],
        ['DN3U', 'B1', dest_tube4.barcode.human],
        ['DN3U', 'A2', dest_tube2.barcode.human],
        ['DN3U', 'B2', dest_tube5.barcode.human],
        ['DN3U', 'A3', dest_tube3.barcode.human],
        ['DN3U', 'B3', dest_tube6.barcode.human]
      ]
    end

    before { assign(:plate, source_labware) }

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

      let(:expected_content) { [['Source plate barcode', 'Source well position', 'Destination tube barcode']] }

      it 'does not show sample rows' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end
  end
end

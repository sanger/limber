# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/bioscan_mbrave.tsv.erb' do
  let(:labware) do
    outer_request = create :library_request, state: 'pending', priority: 0
    meta0 =
      create(:sample_metadata_for_mbrave, supplier_name: 'meta0', cohort: 'cohort0', sample_description: 'desc0')
    sample0 = create(:sample, sample_metadata: meta0)
    meta1 =
      create(:sample_metadata_for_mbrave, supplier_name: 'meta1', cohort: 'cohort1', sample_description: 'desc1')
    sample1 = create(:sample, sample_metadata: meta1)
    meta2 =
      create(:sample_metadata_for_mbrave, supplier_name: 'meta2', cohort: 'cohort2', sample_description: 'desc2')
    sample2 = create(:sample, sample_metadata: meta2)
    meta3 =
      create(:sample_metadata_for_mbrave, supplier_name: 'meta3', cohort: 'cohort3', sample_description: 'desc3')
    sample3 = create(:sample, sample_metadata: meta3)
    aliquots = [
      create(
        :tagged_aliquot_for_mbrave,
        well_location: 'C10',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample1,
        tag: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_forward_96_v2')),
        tag2: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_reverse_4_11_v2'))
      ),
      create(
        :tagged_aliquot_for_mbrave,
        well_location: 'A01',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample2,
        tag: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_forward_96_v2')),
        tag2: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_reverse_4_7_v2'))
      ),
      create(
        :tagged_aliquot_for_mbrave,
        well_location: 'A01',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample0,
        tag: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_forward_96_v2')),
        tag2: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_reverse_4_1_v2'))
      ),
      create(
        :tagged_aliquot_for_mbrave,
        well_location: 'H12',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample3,
        tag: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_forward_96_v2')),
        tag2: create(:tag, tag_group: create(:tag_group, name: 'Bioscan_reverse_4_24_v2'))
      )
    ]
    create(:tube, aliquots:)
  end

  before { assign(:tube, labware) }

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render, col_sep: "\t")
    expect(parsed_csv).to eq(
      [
        ['Forward Labels', 'Reverse Labels', 'Label', 'Group', 'UMI plate ID', 'Sample Plate ID'],
        %w[PB1F_bc1001 PB1R_bc1097_rc meta0 cohort0 1 desc0],
        %w[PB1F_bc1001 PB1R_bc1121_rc meta2 cohort2 7 desc2],
        %w[PB1F_bc1075 PB1R_bc1139_rc meta1 cohort1 11 desc1],
        %w[PB1F_bc1096 PB1R_bc1192_rc meta3 cohort3 24 desc3]
      ]
    )
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/bioscan_mbrave.tsv.erb' do
  has_a_working_api

  let(:labware) do
    outer_request = create :library_request, state: 'pending', priority: 0
    meta1 =
      create(:v2_sample_metadata_for_mbrave, supplier_name: 'meta1', cohort: 'cohort1', sample_description: 'desc1')
    sample1 = create(:v2_sample, sample_metadata: meta1)
    meta2 =
      create(:v2_sample_metadata_for_mbrave, supplier_name: 'meta2', cohort: 'cohort2', sample_description: 'desc2')
    sample2 = create(:v2_sample, sample_metadata: meta2)
    aliquots = [
      create(
        :v2_tagged_aliquot_for_mbrave,
        well_location: 'C10',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample1
      ),
      create(
        :v2_tagged_aliquot_for_mbrave,
        well_location: 'A01',
        library_state: 'pending',
        outer_request: outer_request,
        sample: sample2
      )
    ]
    create(:v2_tube, aliquots: aliquots)
  end

  before { assign(:tube, labware) }

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render, col_sep: "\t")
    expect(parsed_csv).to eq(
      [
        ['Forward Labels', 'Reverse Labels', 'Label', 'Group', 'UMI plate ID', 'Sample Plate ID'],
        %w[PB1F_bc1001 PB1R_bc1097_rc meta2 cohort2 1 desc2],
        %w[PB1F_bc1075 PB1R_bc1099_rc meta1 cohort1 1 desc1]
      ]
    )
  end
end

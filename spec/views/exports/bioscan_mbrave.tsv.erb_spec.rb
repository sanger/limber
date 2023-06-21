# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/bioscan_mbrave.tsv.erb' do
  has_a_working_api

  let(:labware) { create(:v2_tube, aliquot_factory: :v2_tagged_aliquot_for_mbrave) }

  before { assign(:tube, labware) }

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render, col_sep: "\t")
    expect(parsed_csv).to eq(
      [
        ['Forward Labels', 'Reverse Labels', 'Label', 'Group', 'UMI plate ID', 'Sample Plate ID'],
        [
          'PB1F_bc1001',
          'PB1R_bc1097_rc',
          labware.aliquots[0].sample.sample_metadata.supplier_name,
          labware.aliquots[0].sample.sample_metadata.cohort,
          '1',
          labware.aliquots[0].sample.sample_metadata.sample_description
        ],
        [
          'PB1F_bc1001',
          'PB1R_bc1097_rc',
          labware.aliquots[1].sample.sample_metadata.supplier_name,
          labware.aliquots[1].sample.sample_metadata.cohort,
          '1',
          labware.aliquots[1].sample.sample_metadata.sample_description
        ]
      ]
    )
  end
end

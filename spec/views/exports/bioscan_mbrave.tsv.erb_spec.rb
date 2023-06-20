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
        ['PB1F_bc1001', 'PB1R_bc1097_rc', 'supplier name 1', 'cohort 1', '1', 'sample description 1'],
        ['PB1F_bc1001', 'PB1R_bc1097_rc', 'supplier name 2', 'cohort 2', '1', 'sample description 2']
      ]
    )
  end

  it 'sorts rows' do
    labware.aliquots[0].sample.sample_metadata.supplier_name = 'sample_SQPU-38319-K_H12'
    labware.aliquots[0].sample.sample_metadata.cohort = 'x'
    labware.aliquots[0].sample.sample_metadata.sample_description = 'x'

    labware.aliquots[1].sample.sample_metadata.supplier_name = 'sample_SQPU-38225-F_A1'
    labware.aliquots[1].sample.sample_metadata.cohort = 'x'
    labware.aliquots[1].sample.sample_metadata.sample_description = 'x'

    parsed_csv = CSV.parse(render, col_sep: "\t")

    # Because of the 96 plate barcode, sample_SQPU-38319-K_H12 is sorted to the end
    expect(parsed_csv).to eq(
      [
        ['Forward Labels', 'Reverse Labels', 'Label', 'Group', 'UMI plate ID', 'Sample Plate ID'],
        %w[PB1F_bc1001 PB1R_bc1097_rc sample_SQPU-38225-F_A1 x 1 x],
        %w[PB1F_bc1001 PB1R_bc1097_rc sample_SQPU-38319-K_H12 x 1 x]
      ]
    )
  end
end

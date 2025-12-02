# frozen_string_literal: true

RSpec.describe 'exports/hamilton_lrc_pbmc_aliquot_to_cellaca_count.csv.erb' do
  let(:wells) do
    (1..12).map do |index| # one-based index
      supplier_name = "vac-tube-barcode-#{index}"
      sample_metadata = create(:sample_metadata, supplier_name:)
      sample = create(:sample, sample_metadata:)
      aliquots = [create(:aliquot, sample:)]
      location = WellHelpers.well_at_column_index(index - 1)
      create(:well, aliquots:, location:)
    end
  end

  let(:plate) do
    # Empty wells will be filtered out.
    wells[0].aliquots = []
    wells[1].aliquots = []

    # Failed wells will be filtered out.
    wells[2].state = 'failed'
    wells[3].state = 'failed'

    create(:plate, wells:)
  end

  let(:workflow) { 'scRNA Core LRC PBMC Aliquot Cell Count' }

  let(:expected_content) do
    header = [
      ['Workflow', workflow],
      [],
      ['Plate Barcode', 'Well Position', 'Vac Tube Barcode', 'Sample Name', 'Well Name']
    ]
    body =
      (5..12).map do |index| # one-based index
        well = plate.wells_in_columns[index - 1]
        sample = well.aliquots.first.sample
        [plate.labware_barcode.human, well.location, sample.sample_metadata.supplier_name, sample.name, well.name]
      end
    header + body
  end

  before do
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  it 'renders the expected number of rows' do
    rows = CSV.parse(render)
    expect(rows.size).to eq(11) # 8 body + 3 header rows
  end

  it 'renders the expected content' do
    rows = CSV.parse(render)
    expect(rows).to eq(expected_content)
  end
end

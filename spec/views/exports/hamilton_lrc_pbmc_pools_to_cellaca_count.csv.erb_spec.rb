# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lrc_pbmc_pools_to_cellaca_count.csv.erb' do
  let(:wells) do
    # 8 because of the Pools plate.
    (1..8).map do |index| # one-based index
      aliquots = []

      # Initiate 10 aliquots per each well
      (1..10).each do |_i|
        supplier_name = "vac-tube-barcode-#{index}"
        sample_metadata = create(:sample_metadata, supplier_name:)
        sample = create(:sample, sample_metadata:)
        aliquots << create(:aliquot, sample:)
      end
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

  # Constants from config/initializers/scrna_config.rb
  let(:scrna_config) { Rails.application.config.scrna_config }
  let(:wastage_factor) { scrna_config[:wastage_factor] }
  let(:desired_chip_loading_concentration) { scrna_config[:desired_chip_loading_concentration] }

  let(:workflow) { 'scRNA Core LRC PBMC Pools Cell Count' }

  let(:expected_content) do
    header = [['Workflow', workflow], [], ['Plate Barcode', 'Well Position', 'Well Name', 'Source Well Volume']]
    body =
      # 8 wells - first two wells (empty + failed)
      (5..8).map do |index| # one-based index
        well = plate.wells_in_columns[index - 1]
        [
          plate.labware_barcode.human,
          well.location,
          well.name,
          format(
            '%0.1f',
            (well.aliquots.size * required_number_of_cells_per_sample_in_pool *
             wastage_factor.call(well.aliquots.size)) /
              desired_chip_loading_concentration
          )
        ]
      end
    header + body
  end

  before do
    Settings.purposes = { plate.purpose.uuid => { presenter_class: {} } }
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  let(:required_number_of_cells_per_sample_in_pool) { scrna_config[:required_number_of_cells_per_sample_in_pool] }

  it 'renders the expected content' do
    rows = CSV.parse(render)

    # Only 4 wells (out of 8; the rest are either emtpy or failed) used
    expect(rows.size).to eq(7) # 4 body + 3 header rows
    expect(rows).to eq(expected_content)
  end
end

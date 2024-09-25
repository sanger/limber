# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lrc_pbmc_pools_to_cellaca_count.csv.erb' do
  has_a_working_api

  let(:wells) do
    # 8 because of the Pools plate.
    (1..8).map do |index| # one-based index
      aliquots = []

      # Initiate 10 aliquots per each well
      (1..10).each do |_i|
        supplier_name = "vac-tube-barcode-#{index}"
        sample_metadata = create(:v2_sample_metadata, supplier_name:)
        sample = create(:v2_sample, sample_metadata:)
        aliquots << create(:v2_aliquot, sample:)
      end
      location = WellHelpers.well_at_column_index(index - 1)
      create(:v2_well, aliquots:, location:)
    end
  end

  let(:plate) do
    # Empty wells will be filtered out.
    wells[0].aliquots = []
    wells[1].aliquots = []

    # Failed wells will be filtered out.
    wells[2].state = 'failed'
    wells[3].state = 'failed'

    create(:v2_plate, wells:)
  end

  let(:required_number_of_cells) { 30_000 }
  let(:wastage_factor) { 0.95238 }
  let(:desired_chip_loading_concentration) { 2_400 }

  before do
    Settings.purposes = {
      plate.purpose.uuid => {
        presenter_class: {
          args: {
            required_number_of_cells:,
            wastage_factor:,
            desired_chip_loading_concentration:
          }
        }
      }
    }
  end

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
            '%0.2f',
            ((well.aliquots.size * required_number_of_cells * wastage_factor) / desired_chip_loading_concentration)
          )
        ]
      end
    header + body
  end

  before do
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  it 'renders the expected content' do
    rows = CSV.parse(render)

    # Only 4 wells (out of 8; the rest are either emtpy or failed) used
    expect(rows.size).to eq(7) # 4 body + 3 header rows
    expect(rows).to eq(expected_content)
  end
end

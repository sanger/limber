# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/hamilton_lrc_pbmc_pools_to_cellaca_count.csv.erb' do
  has_a_working_api

  let(:wells) do
    (1..12).map do |index|  # one-based index
      supplier_name = "vac-tube-barcode-#{index}"
      sample_metadata = create(:v2_sample_metadata, supplier_name: supplier_name)
      sample = create(:v2_sample, sample_metadata: sample_metadata)
      aliquots = [create(:v2_aliquot, sample: sample)]
      location = WellHelpers.well_at_column_index(index - 1)
      create(:v2_well, aliquots: aliquots, location: location)
    end
  end

  let(:plate) do
    # Empty wells will be filtered out.
    wells[0].aliquots = []
    wells[1].aliquots = []

    # Failed wells will be filtered out.
    wells[2].state = 'failed'
    wells[3].state = 'failed'

    create(:v2_plate, wells: wells)
  end

  before do
    Settings.purposes = {
      plate.purpose.uuid => {
        presenter_class: {
          args: {
            required_number_of_cells: 30_000,
            wastage_factor: 0.95238,
            desired_chip_loading_concentration: 2_400,
          }
        }
      }
    }
  end

  let(:workflow) { 'scRNA Core LRC PBMC Pools Cell Count' }

  let(:expected_content) do
    header = [
      ['Workflow', workflow],
      [],
      ['Plate Barcode', 'Well Position', 'Well Name', 'Source Well Volume']
    ]
    body =
      (5..12).map do |index|  # one-based index
        well = plate.wells_in_columns[index - 1]
        source_well_vol =
        [plate.labware_barcode.human, well.location, well.name,
            '%0.2f' % ((well.aliquots.size * 30_000 * 0.95238) / 2_400)]
      end
    header + body
  end

  before do
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  it 'renders the expected content' do
    rows = CSV.parse(render)
    expect(rows.size).to eq(11) # 8 body + 3 header rows
    expect(rows).to eq(expected_content)
  end
end

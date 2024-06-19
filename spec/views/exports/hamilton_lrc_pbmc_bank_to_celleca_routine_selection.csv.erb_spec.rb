# frozen_string_literal: true

RSpec.describe 'exports/hamilton_lrc_pbmc_bank_to_celleca_routine_selection.csv.erb' do
  has_a_working_api

  let(:number_of_tubes) { 12 }

  let(:ancestor_tubes) do
    # Similar to LRC Blood Vac tubes.
    (1..number_of_tubes).each_with_object({}) do |index, hash|
      uuid = "sample-uuid-#{index}"
      tube = create(:v2_stock_tube)
      hash[uuid] = tube
    end
  end

  let(:plate) do
    # Similar to LRC PBMC Bank plate.
    number_of_wells = number_of_tubes * 3 # pair consolidation: 6 -> 3
    wells =
      (1..number_of_wells).each_with_object([]) do |index, array|
        suffix = ((index - 1) / 3) + 1
        uuid = "sample-uuid-#{suffix}" # Match the samples of tubes
        sample = create(:v2_sample, uuid: uuid)
        aliquots = [create(:v2_aliquot, sample: sample)]
        location = WellHelpers.well_at_column_index(index - 1)
        array << create(:v2_well, aliquots: aliquots, location: location)
      end
    create(:v2_plate, wells: wells)
  end

  let(:export_id) { 'hamilton_lrc_pbmc_bank_to_celleca_routine_selection' }

  let(:workflow) { 'scRNA Core LRC PBMC Bank Cell Count' }

  before do
    assign(:ancestor_tubes, ancestor_tubes)
    assign(:plate, plate)
    assign(:workflow, workflow)

    # The view needs the export id to find the count option from the purpose config.
    export = double('Export', id: export_id)
    assign(:export, export)

    # Set the count option in purpose config.
    Settings.purposes[plate.purpose.uuid] = { file_links: [{ id: export.id, count: 6 }] }
  end

  let(:expected_content) do
    header = [
      ['Workflow', workflow],
      ['Plate Barcode', 'Well Position', 'Vac Tube Barcode', 'Sample Name', 'Well Name']
    ]
    rows =
      %w[A1 H1 G2 F3 E4 D5].map do |location|
        well = plate.well_at_location(location)
        sample = well.aliquots.first.sample
        [
          plate.labware_barcode.human,
          well.location,
          ancestor_tubes[sample.uuid].labware_barcode.human,
          sample.name,
          well.name
        ]
      end
    header + rows
  end

  it 'renders the expected content' do
    content = CSV.parse(render)

    expect(content.size).to eq(8) # workflow + column headers + 6 rows
    expect(content[0]).to eq(expected_content[0]) # workflow header
    expect(content[1]).to eq(expected_content[1]) # column headers

    (2..6).each do |index|
      expect(content[index]).to eq(expected_content[index]) # row
    end
  end
end

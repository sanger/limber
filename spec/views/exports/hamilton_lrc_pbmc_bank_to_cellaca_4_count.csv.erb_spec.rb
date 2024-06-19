# frozen_string_literal: true

RSpec.describe 'Hamilton LRC PBMC Bank to Cellaca CSV Exports', type: :view do
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

  let(:workflow) { 'scRNA Core LRC PBMC Bank Cell Count' }

  let(:template) { "exports/hamilton_lrc_pbmc_bank_to_cellaca_#{count}_count" }

  before do
    assign(:ancestor_tubes, ancestor_tubes)
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  context 'with hamilton_lrc_pbmc_bank_to_cellaca_4_count' do
    let(:count) { 4 }
    it 'renders the expected content' do
      render(template: template)
      content = CSV.parse(rendered)
      expect(content).to eq(expected_content(count))
    end
  end

  context 'with hamilton_lrc_pbmc_bank_to_cellaca_6_count' do
    let(:count) { 6 }
    it 'renders the expected content' do
      render(template: template)
      content = CSV.parse(rendered)
      expect(content).to eq(expected_content(count))
    end
  end

  context 'with hamilton_lrc_pbmc_bank_to_cellaca_12_count' do
    let(:count) { 6 }
    it 'renders the expected content' do
      render(template: template)
      content = CSV.parse(rendered)
      expect(content).to eq(expected_content(count))
    end
  end

  context 'with hamilton_lrc_pbmc_bank_to_cellaca_all_count' do
    let(:count) { nil }
    let(:template) { 'exports/hamilton_lrc_pbmc_bank_to_cellaca_all_count' }
    it 'renders the expected content' do
      render(template: template)
      content = CSV.parse(rendered)
      expect(content).to eq(expected_content(count))
    end
  end

  # Generates the expected content based on the number of wells to select.
  #
  # @param count [Integer] The number of wells to select.
  # @return [Array<Array<String>>] The expected CSV content.
  def expected_content(count)
    locations = Utility::CellCountSpotChecking.new(plate, ancestor_tubes).select_wells(count).map(&:location)
    header = [
      ['Workflow', workflow],
      [],
      ['Plate Barcode', 'Well Position', 'Vac Tube Barcode', 'Sample Name', 'Well Name']
    ]
    rows =
      locations.map do |location|
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
end

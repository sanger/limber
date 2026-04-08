# frozen_string_literal: true

RSpec.describe 'Hamilton LRC PBMC Bank to Cellaca CSV Exports', type: :view do
  let(:number_of_tubes) { 12 }

  let(:ancestor_tubes) do
    # Similar to LRC Blood Vac tubes.
    (1..number_of_tubes).each_with_object({}) do |index, hash|
      uuid = "sample-uuid-#{index}"
      tube = create(:stock_tube)
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
        supplier_name = ancestor_tubes[uuid].barcode.human
        sample_metadata = create(:sample_metadata, supplier_name:)
        sample = create(:sample, uuid:, sample_metadata:)
        aliquots = [create(:aliquot, sample:)]
        location = WellHelpers.well_at_column_index(index - 1)
        array << create(:well, aliquots:, location:)
      end
    create(:plate, wells:)
  end

  let(:workflow) { 'scRNA Core LRC PBMC Bank Cell Count' }

  before do
    assign(:plate, plate)
    assign(:workflow, workflow)
  end

  context 'with first replicates' do
    let(:template) { 'exports/hamilton_lrc_pbmc_bank_to_cellaca_first_count' }

    it 'renders the expected content' do
      render(template:)
      content = CSV.parse(rendered)
      selected_wells = Utility::CellCountSpotChecking.new(plate).first_replicates
      expect(content).to eq(expected_content(selected_wells))
    end
  end

  context 'with second replicates' do
    let(:template) { 'exports/hamilton_lrc_pbmc_bank_to_cellaca_second_count' }

    it 'renders the expected content' do
      render(template:)
      content = CSV.parse(rendered)
      selected_wells = Utility::CellCountSpotChecking.new(plate).second_replicates
      expect(content).to eq(expected_content(selected_wells))
    end
  end

  # Generates the expected content based on the number of wells to select.
  #
  # @param selected_wells [Array<Well>] first or second replicate wells
  # @return [Array<Array<String>>] The expected CSV content.
  # rubocop:disable Metrics/AbcSize
  def expected_content(selected_wells)
    header = [
      ['Workflow', workflow],
      [],
      ['Plate Barcode', 'Well Position', 'Vac Tube Barcode', 'Sample Name', 'Well Name']
    ]
    rows =
      selected_wells.map do |well|
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
  # rubocop:enable Metrics/AbcSize
end

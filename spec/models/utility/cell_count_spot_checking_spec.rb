# frozen_string_literal: true

# This test checks well selection for different number of ancestor tubes and
# specifications of the number of wells to select.
RSpec.describe Utility::CellCountSpotChecking do
  let(:number_of_tubes) { 4 }

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
        supplier_name = ancestor_tubes[uuid].barcode.human
        sample_metadata = create(:v2_sample_metadata, supplier_name: supplier_name)
        sample = create(:v2_sample, uuid: uuid, sample_metadata: sample_metadata)
        aliquots = [create(:v2_aliquot, sample: sample)]
        location = WellHelpers.well_at_column_index(index - 1)
        array << create(:v2_well, aliquots: aliquots, location: location)
      end
    create(:v2_plate, wells: wells)
  end

  subject { described_class.new(plate) }

  describe '#initialize' do
    it 'sets the plate and ancestor tubes' do
      # Using attribute readers
      expect(subject.plate).to eq(plate)
    end
  end

  describe '#first_replicates' do
    it 'returns the first well for each of ancestor tube' do
      # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
      # ->
      # ["A1", "D1", "G1", "B2"]
      result = subject.first_replicates
      expect(result.size).to eq(ancestor_tubes.size)
      selected_wells = plate.wells_in_columns.reject(&:empty?).map(&:location).each_slice(3).map(&:first)
      expect(result.map(&:location)).to eq(selected_wells)
    end
  end

  describe '#second_replicates' do
    it 'returns the second well for each ancestor tube' do
      # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
      # ->
      # ["B1", "E1", "H1", "C2"]
      result = subject.second_replicates
      expect(result.size).to eq(ancestor_tubes.size)
      selected_wells = plate.wells_in_columns.reject(&:empty?).map(&:location).each_slice(3).map(&:second)
      expect(result.map(&:location)).to eq(selected_wells)
    end
  end
end

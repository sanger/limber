# frozen_string_literal: true

# This test checks well selection for different number of ancestor tubes and
# specifications of the number of wells to select.
RSpec.describe Utility::CellCountSpotChecking do
  subject { described_class.new(plate) }

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
        sample_metadata = create(:v2_sample_metadata, supplier_name:)
        sample = create(:v2_sample, uuid:, sample_metadata:)
        aliquots = [create(:v2_aliquot, sample:)]
        location = WellHelpers.well_at_column_index(index - 1)
        array << create(:v2_well, aliquots:, location:)
      end
    create(:v2_plate, wells:)
  end

  let(:plate_wells_grouped_by_barcode) do
    # Generate an array where each element is an array of wells with the same
    # ancestor tube barcode on the plate.
    plate
      .wells_in_columns
      .reject { |well| well.empty? || well.failed? }
      .group_by { |well| well.aliquots.first.sample.sample_metadata.supplier_name }
      .values
  end

  describe '#initialize' do
    it 'sets the plate and ancestor tubes' do
      # Using attribute readers
      expect(subject.plate).to eq(plate)
    end
  end

  describe '#first_replicates' do
    context 'when there are first replicates for all' do
      it 'returns the first well for each of ancestor tube' do
        # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
        # ->
        # ["A1", "D1", "G1", "B2"]
        result = subject.first_replicates
        expect(result.size).to eq(ancestor_tubes.size)
        selected_wells = plate_wells_grouped_by_barcode.map(&:first)
        expect(result).to eq(selected_wells)
      end
    end

    context 'when a first replicate is failed' do
      before do
        # Well state is set for testing purposes. In the actual code, the state
        # is a computed property; there is no way to set it directly.
        plate.wells_in_columns.first.state = 'failed' # Fail A1
      end

      it 'returns the second replicate as the first replicate' do
        # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
        # ->
        # ["B1", "D1", "G1", "B2"]
        result = subject.first_replicates
        expect(result.size).to eq(ancestor_tubes.size)
        selected_wells = plate_wells_grouped_by_barcode.map(&:first)
        expect(result).to eq(selected_wells)
      end
    end
  end

  describe '#second_replicates' do
    context 'when there are second replicates for all' do
      it 'returns the second well for each ancestor tube' do
        # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
        # ->
        # ["B1", "E1", "H1", "C2"]
        result = subject.second_replicates
        expect(result.size).to eq(ancestor_tubes.size)
        selected_wells = plate_wells_grouped_by_barcode.map(&:second)
        expect(result).to eq(selected_wells)
      end
    end

    context 'when a second replicate is failed' do
      before do
        # Well state is set for testing purposes. In the actual code, the state
        # is a computed property; there is no way to set it directly.
        plate.wells_in_columns.second.state = 'failed' # Fail B1
      end

      it 'returns the following replicate as the second replicate' do
        # ['A1', 'B1', 'C1', 'D1', 'E1', 'F1', 'G1', 'H1', 'A2', 'B2', 'C2', 'D2']
        # ->
        # ["C1", "E1", "H1", "C2"]
        result = subject.second_replicates
        expect(result.size).to eq(ancestor_tubes.size)
        selected_wells = plate_wells_grouped_by_barcode.map(&:second)
        expect(result).to eq(selected_wells)
      end
    end

    context 'when there are no second replicate wells' do
      before do
        # Remove all replicate wells except the first ones
        plate.wells.replace(plate.wells.each_slice(3).pluck(0))
      end

      it 'returns an empty array' do
        result = subject.second_replicates
        expect(result.size).to eq(0)
      end
    end

    context 'when an ancestor tube has no second replicates' do
      before do
        # Remove all second replicates of the first ancestor tube
        second_replicates_to_remove =
          plate
            .wells
            .select do |well|
            sample = well.aliquots.first.sample
            sample.sample_metadata.supplier_name == ancestor_tubes.values.first.barcode.human
          end
            .drop(1)
        plate.wells.reject! { |well| second_replicates_to_remove.include?(well) }
      end

      it 'does not include any wells for the ancestor tube with no second replicates' do
        result = subject.second_replicates
        expect(result.size).to eq(ancestor_tubes.size - 1)

        # The first vac tube barcode is not in the result
        barcodes = result.map { |well| well.aliquots.first.sample.sample_metadata.supplier_name }
        expect(barcodes).not_to include(ancestor_tubes.values.first.barcode.human)
      end
    end
  end
end

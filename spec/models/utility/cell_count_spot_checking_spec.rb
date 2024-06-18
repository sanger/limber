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
        sample = create(:v2_sample, uuid: uuid)
        aliquots = [create(:v2_aliquot, sample: sample)]
        location = WellHelpers.well_at_column_index(index - 1)
        array << create(:v2_well, aliquots: aliquots, location: location)
      end
    create(:v2_plate, wells: wells)
  end

  subject { described_class.new(plate, ancestor_tubes) }

  describe '#initialize' do
    it 'sets the plate and ancestor tubes' do
      # Using attribute readers
      expect(subject.plate).to eq(plate)
      expect(subject.ancestor_tubes).to eq(ancestor_tubes)
    end
  end

  describe '#select_wells' do
    context 'when the number of ancestor tubes is 4' do
      it 'selects wells up to count if specified' do
        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1", "A2", "B2", "C2", "D2"]
        # ->
        # ["A1", "E1", "A2", "D2"]
        count = 4
        result = subject.select_wells(count)
        expect(result.size).to eq(count)
        expect(result[0].location).to eq('A1')
        expect(result[1].location).to eq('E1')
        expect(result[2].location).to eq('A2')
        expect(result[3].location).to eq('D2')
      end

      it 'selects wells up to the number of ancestor tubes if count is not specified' do
        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1", "A2", "B2", "C2", "D2"]
        # ->
        # ["A1", "E1", "A2", "D2"]
        result = subject.select_wells
        expect(result.size).to eq(ancestor_tubes.size)
        expect(result[0].location).to eq('A1')
        expect(result[1].location).to eq('E1')
        expect(result[2].location).to eq('A2')
        expect(result[3].location).to eq('D2')
      end
    end

    context 'when the number of ancestor tubes is 6' do
      let(:number_of_tubes) { 6 }

      it 'selects wells up to count if specified' do
        count = 4 # lower than the number of ancestor tubes
        result = subject.select_wells(count)

        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1",
        #  "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2",
        #  "A3", "B3"]
        #  ->
        # ["A1", "G1", "E2", "B3"]

        expect(result.size).to eq(count)
        expect(result[0].location).to eq('A1')
        expect(result[1].location).to eq('G1')
        expect(result[2].location).to eq('E2')
        expect(result[3].location).to eq('B3')
      end

      it 'selects wells up to the number of ancestor tubes if count is not specified' do
        result = subject.select_wells

        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1",
        #  "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2",
        #  "A3", "B3"]
        #  ->
        # ["A1", "E1", "A2", "D2", "G2", "B3"]

        expect(result.size).to eq(ancestor_tubes.size)
        expect(result[0].location).to eq('A1')
        expect(result[1].location).to eq('E1')
        expect(result[2].location).to eq('A2')
        expect(result[3].location).to eq('D2')
        expect(result[4].location).to eq('G2')
        expect(result[5].location).to eq('B3')
      end
    end

    context 'when the number of ancestor tubes is 12' do
      let(:number_of_tubes) { 12 }

      it 'selects wells up to count if specified' do
        count = 6 # lower than the number of ancestor tubes
        result = subject.select_wells(count)

        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1",
        #  "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2",
        #  "A3", "B3", "C3", "D3", "E3", "F3", "G3", "H3",
        #  "A4", "B4", "C4", "D4", "E4", "F4", "G4", "H4",
        #  "A5", "B5", "C5", "D5"]
        # ->
        # ["A1", "H1", "G2", "F3", "E4", "D5"]

        expect(result.size).to eq(count)
        expect(result[0].location).to eq('A1')
        expect(result[1].location).to eq('H1')
        expect(result[2].location).to eq('G2')
        expect(result[3].location).to eq('F3')
        expect(result[4].location).to eq('E4')
        expect(result[5].location).to eq('D5')
      end

      it 'selects wells up to the number of ancestor tubes if count is not specified' do
        result = subject.select_wells
        expect(result.size).to eq(ancestor_tubes.size)

        # ["A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1",
        #  "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2",
        #  "A3", "B3", "C3", "D3", "E3", "F3", "G3", "H3",
        #  "A4", "B4", "C4", "D4", "E4", "F4", "G4", "H4",
        #  "A5", "B5", "C5", "D5"]
        # ->
        # ["A1", "E1", "A2", "D2", "G2", "B3", "E3", "H3", "C4", "F4", "A5", "D5"]

        expect(result[0].location).to eq('A1') # 0
        expect(result[1].location).to eq('E1') # +4 (fair sharing remainder)
        expect(result[2].location).to eq('A2') # +4 (fair sharing remainder)
        expect(result[3].location).to eq('D2') # +3
        expect(result[4].location).to eq('G2') # +3
        expect(result[5].location).to eq('B3') # +3
        expect(result[6].location).to eq('E3') # +3
        expect(result[7].location).to eq('H3') # +3
        expect(result[8].location).to eq('C4') # +3
        expect(result[9].location).to eq('F4') # +3
        expect(result[10].location).to eq('A5') # +3
        expect(result[11].location).to eq('D5') # +3
      end
    end
  end
end

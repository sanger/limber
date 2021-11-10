# frozen_string_literal: true

RSpec.describe TransfersHelper do
  let(:source_molarity) { 15 }
  let(:return_value) do
    calculate_pick_volumes(target_molarity: 5, target_volume: 200, minimum_pick: 2, source_molarity: source_molarity)
  end
  let(:sample_volume) { return_value[:sample_volume] }
  let(:buffer_volume) { return_value[:buffer_volume] }

  shared_examples 'volume calculator' do
    it 'returns a valid hash' do
      expect(return_value).to be_a(Hash)
      expect(return_value.keys).to eq(%i[sample_volume buffer_volume])
      expect(return_value.values).to all be_a Numeric
    end
  end

  context 'default inputs' do
    it_behaves_like 'volume calculator'

    it 'has the correct outputs' do
      expect(sample_volume).to be_within(0.001).of(66.667)
      expect(buffer_volume).to be_within(0.001).of(133.333)
    end
  end

  context 'low concentration sample' do
    let(:source_molarity) { 3 }

    it_behaves_like 'volume calculator'

    it 'has the correct outputs' do
      expect(sample_volume).to be_within(0.001).of(200)
      expect(buffer_volume).to be_within(0.001).of(0)
    end
  end

  context 'low buffer pick volume' do
    let(:source_molarity) { 5.02 }

    it_behaves_like 'volume calculator'

    it 'has the correct outputs' do
      expect(sample_volume).to be_within(0.001).of(200)
      expect(buffer_volume).to be_within(0.001).of(0)
    end
  end

  context 'low sample pick volume' do
    let(:source_molarity) { 750 }

    it_behaves_like 'volume calculator'

    it 'has the correct outputs' do
      expect(sample_volume).to be_within(0.001).of(2)
      expect(buffer_volume).to be_within(0.001).of(198)
    end
  end
end

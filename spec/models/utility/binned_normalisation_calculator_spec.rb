# frozen_string_literal: true

RSpec.describe Utility::BinnedNormalisationCalculator do
  context 'when computing values' do
    subject { Utility::BinnedNormalisationCalculator.new(dilutions_config) }

    let(:dilutions_config) do
      {
        'target_amount_ng' => 50,
        'target_volume' => 20,
        'minimum_source_volume' => 0.2
      }
    end

    describe '#compute_vol_source_reqd' do
      context 'when sample concentration is within range' do
        let(:sample_conc) { 50.0 }

        it 'returns expected volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(1.0)
        end
      end

      context 'when sample concentration is zero' do
        let(:sample_conc) { 0.0 }

        it 'returns the maximum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      context 'when sample concentration is below range minimum' do
        let(:sample_conc) { 2.0 }

        it 'returns the maximum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(20.0)
        end
      end

      context 'when sample concentration is above range maximum' do
        let(:sample_conc) { 500.0 }

        it 'returns the minimum volume' do
          expect(subject.compute_vol_source_reqd(sample_conc)).to eq(0.2)
        end
      end
    end
  end
end

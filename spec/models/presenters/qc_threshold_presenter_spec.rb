# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Presenters::QcThresholdPresenter do
  subject(:presenter) { described_class.new(plate, configuration) }

  let(:plate) { instance_double(Sequencescape::Api::V2::Plate, wells: wells) }
  let(:wells) { qc_results.map { |results| instance_double(Sequencescape::Api::V2::Well, all_latest_qc: results) } }
  let(:qc_results) do
    [
      [
        create(:qc_result, key: 'molarity', value: '10', units: 'nM'),
        create(:qc_result, key: 'concentration', value: '10', units: 'ng/ul'),
        create(:qc_result, key: 'viability', value: '10', units: '%'),
        create(:qc_result, key: 'volume', value: '1000', units: 'ul')
      ],
      [
        create(:qc_result, key: 'molarity', value: '50.12345', units: 'nM'),
        create(:qc_result, key: 'viability', value: '20', units: '%'),
        create(:qc_result, key: 'volume', value: '1', units: 'ml')
      ]
    ]
  end

  describe '#thresholds' do
    context 'with no configuration' do
      let(:configuration) { {} }

      it 'reads the thresholds from the wells' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity'),
          have_attributes(name: 'concentration'),
          have_attributes(name: 'viability'),
          have_attributes(name: 'volume')
        )
      end

      it 'sets limits derived from the wells' do
        # NOTE: Maximum and minimum values need to have the same (or lower) precision
        # as the step, otherwise the browser will adopt this precision
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', max: 52.13, min: 7.99),
          have_attributes(name: 'concentration', max: 10.0, min: 10.0),
          have_attributes(name: 'viability', min: 0, max: 100),
          have_attributes(name: 'volume', min: 1000.0, max: 1000.0)
        )
      end

      it 'picks the most precise set of units' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', units: 'nM'),
          have_attributes(name: 'concentration', units: 'ng/ul'),
          have_attributes(name: 'viability', units: '%'),
          have_attributes(name: 'volume', units: 'ul')
        )
      end

      it 'sets defaults to 0' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', default: 0),
          have_attributes(name: 'concentration', default: 0),
          have_attributes(name: 'viability', default: 0),
          have_attributes(name: 'volume', default: 0)
        )
      end

      it 'picks a step of 0.01' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', step: 0.01),
          have_attributes(name: 'concentration', step: 0.01),
          have_attributes(name: 'viability', step: 0.01),
          have_attributes(name: 'volume', step: 0.01)
        )
      end

      it 'is enabled' do
        expect(presenter.thresholds).to all be_enabled
      end
    end

    context 'with no QC results for a configured key' do
      let(:qc_results) do
        [
          [create(:qc_result, key: 'concentration', value: '10', units: 'ng/ul')],
          [create(:qc_result, key: 'concentration', value: '50', units: 'nM')]
        ]
      end
      let(:configuration) { { molarity: { name: 'molarity', default_threshold: 20, max: 50, min: 5, units: 'nM' } } }

      it 'is disabled' do
        expect(presenter.thresholds.first).to_not be_enabled
      end

      it 'explains the problem' do
        expect(presenter.thresholds.first.error).to eq 'There are no QC results of this type to apply a threshold.'
      end
    end

    context 'with incompatible units' do
      let(:qc_results) do
        [
          [create(:qc_result, key: 'concentration', value: '10', units: 'ng/ul')],
          [create(:qc_result, key: 'concentration', value: '50', units: 'nM')]
        ]
      end
      let(:configuration) { {} }

      it 'is disabled' do
        expect(presenter.thresholds.first).to_not be_enabled
      end

      it 'explains the problem' do
        expect(presenter.thresholds.first.error).to eq 'Incompatible units ng/ul, nM. Automatic thresholds disabled.'
      end
    end

    context 'with configuration' do
      let(:configuration) do
        {
          molarity: {
            name: 'molarity',
            default_threshold: 20,
            max: 50,
            min: 5,
            units: 'nM'
          },
          cell_count: {
            name: 'cell count',
            default_threshold: 2,
            max: 5,
            min: 0,
            units: 'cells/ml',
            decimal_places: 0
          },
          volume: {
            name: 'volume',
            units: 'ml'
          }
        }
      end

      it 'reads the thresholds from the provided configuration' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity'),
          have_attributes(name: 'cell count'),
          have_attributes(name: 'concentration'),
          have_attributes(name: 'viability'),
          have_attributes(name: 'volume')
        )
      end

      it 'sets limits derived from the provided configuration' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'cell count', max: 5, min: 0),
          have_attributes(name: 'molarity', max: 50, min: 5),
          have_attributes(name: 'concentration', max: 10.0, min: 10.0),
          have_attributes(name: 'viability', min: 0, max: 100),
          have_attributes(name: 'volume', min: 1.0, max: 1.0) # 1.0 as units specify ml
        )
      end

      it 'picks the configured set of units' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', units: 'nM'),
          have_attributes(name: 'cell count', units: 'cells/ml'),
          have_attributes(name: 'volume', units: 'ml'),
          have_attributes(name: 'concentration', units: 'ng/ul'),
          have_attributes(name: 'viability', units: '%')
        )
      end

      it 'picks the configured defaults' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', default: 20),
          have_attributes(name: 'cell count', default: 2),
          have_attributes(name: 'volume', default: 0),
          have_attributes(name: 'concentration', default: 0),
          have_attributes(name: 'viability', default: 0)
        )
      end

      it 'picks the configured step' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', step: 0.01),
          have_attributes(name: 'cell count', step: 1),
          have_attributes(name: 'volume', step: 0.01),
          have_attributes(name: 'concentration', step: 0.01),
          have_attributes(name: 'viability', step: 0.01)
        )
      end
    end
  end

  describe '#value_for' do
    let(:configuration) { {} }
    let(:qc_to_convert) { create(:qc_result, key: 'volume', value: '1', units: 'ml') }

    # Value for converts all scalar values to an appropriate unit
    it 'converts values to the thresholds unit' do
      expect(presenter.value_for(qc_to_convert)).to eq 1000.0
    end
  end
end

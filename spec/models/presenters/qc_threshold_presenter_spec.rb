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
        create(:qc_result, key: 'molarity', value: '50', units: 'nM'),
        create(:qc_result, key: 'viability', value: '20', units: '%'),
        create(:qc_result, key: 'volume', value: '1', units: 'ml')
      ]
    ]
  end

  describe '#thresholds' do
    context 'with no configuration' do
      let(:configuration) { {} }

      it 'reads the thresholds from the wells' do\
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity'),
          have_attributes(name: 'concentration'),
          have_attributes(name: 'viability'),
          have_attributes(name: 'volume')
        )
      end

      it 'sets limits derived from the wells' do
        expect(presenter.thresholds).to contain_exactly(
          have_attributes(name: 'molarity', max: 52.0, min: 8.0),
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
    end

    context 'with configuration' do
      let(:configuration) do
        {
          molarity: { name: 'molarity', default_threshold: 20, max: 50, min: 5, units: 'nM' },
          cell_count: { name: 'cell count', default_threshold: 2, max: 5, min: 0, units: 'cells/ml' },
          volume: { name: 'volume', units: 'ml' }
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
    end
  end
end

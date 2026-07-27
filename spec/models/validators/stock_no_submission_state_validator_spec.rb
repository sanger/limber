# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Validators::StockNoSubmissionStateValidator do
  subject(:validator) { described_class.new({}) }

  let(:plate) { create(:plate) }
  let(:presenter) { Presenters::StockPlateWithNoSubmissionPresenter.new(labware: plate) }

  describe '#validate' do
    context 'when the plate has no samples (all wells are empty)' do
      # Default create(:plate) has pool_sizes: [] — no aliquots in any well
      it 'adds a no-samples error' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).to include('has no samples. Did the cherry-pick complete successfully?')
      end

      it 'does not add a no-submission error (key difference from StockStateValidator)' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).not_to include(
          'has no requests. Please check that your submission built correctly.'
        )
      end
    end

    context 'when the plate has no submission (pools are empty) but does have samples' do
      let(:plate) { create(:plate, pool_sizes: [2]) }

      before { allow(plate).to receive(:pools).and_return([]) }

      it 'does not add a no-submission error' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).not_to include(
          'has no requests. Please check that your submission built correctly.'
        )
      end

      it 'adds no errors' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).to be_empty
      end
    end

    context 'when the plate has samples and matching pools' do
      # pool_sizes: [2] creates 2 wells with aliquots and requests in one submission
      let(:plate) { create(:plate, pool_sizes: [2]) }

      it 'adds no errors' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).to be_empty
      end
    end

    context 'when a well has requests from multiple submissions (duplicate)' do
      let(:plate) { create(:plate, pool_sizes: [1]) }

      before do
        well_location = plate.wells.first.location
        pool_a = instance_double(Sequencescape::Api::V2::Plate::Pool, id: 'sub-1', well_locations: [well_location])
        pool_b = instance_double(Sequencescape::Api::V2::Plate::Pool, id: 'sub-2', well_locations: [well_location])
        allow(plate).to receive(:pools).and_return([pool_a, pool_b])
      end

      it 'adds a duplicates error' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).to include(a_string_matching(/has multiple submissions on:/))
      end
    end

    context 'when an empty well has a request' do
      # Two wells with requests; stub the first to be empty so filled_wells is non-empty
      # (preventing no_samples? from firing) while the empty well is still listed in the pool
      let(:plate) { create(:plate, pool_sizes: [2]) }

      before do
        empty_well = plate.wells.first
        allow(empty_well).to receive(:aliquots).and_return([])
        pool = instance_double(
          Sequencescape::Api::V2::Plate::Pool,
          id: 'sub-1',
          well_locations: plate.wells.map(&:location)
        )
        allow(plate).to receive(:pools).and_return([pool])
      end

      it 'adds an empty-wells-with-requests error' do
        validator.validate(presenter)
        expect(presenter.errors[:plate]).to include(a_string_matching(/has requests on empty wells:/))
      end
    end
  end
end

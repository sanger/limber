# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Well do
  describe '#contains_control?' do
    let(:well) { create :well }

    context 'with no control' do
      it 'returns false' do
        expect(well.contains_control?).to be(false)
      end
    end

    context 'with control' do
      before { well.aliquots[0].sample.control = true }

      it 'returns true' do
        expect(well.contains_control?).to be(true)
      end
    end
  end

  describe '#control_info_formatted' do
    let(:well) { create :well }

    before { well.aliquots[0].sample.control = true }

    context 'with no control' do
      before { well.aliquots[0].sample.control = false }

      it 'returns nil' do
        expect(well.control_info_formatted).to be_nil
      end
    end

    context 'with positive control' do
      before { well.aliquots[0].sample.control_type = 'positive' }

      it 'is correctly formatted' do
        expect(well.control_info_formatted).to eq('+')
      end
    end

    context 'with negative control' do
      before { well.aliquots[0].sample.control_type = 'negative' }

      it 'is correctly formatted' do
        expect(well.control_info_formatted).to eq('-')
      end
    end

    context 'with control type unspecified' do
      it 'is correctly formatted' do
        expect(well.control_info_formatted).to eq('c')
      end
    end
  end

  describe '#latest_live_cell_count' do
    let(:earlier_live_cell_count) do
      create(
        :qc_result,
        key: 'live_cell_count',
        value: '1000000',
        units: 'cells/ml',
        created_at: Time.utc(2020, 1, 2, 3, 4, 5)
      )
    end
    let(:later_live_cell_count) do
      create(
        :qc_result,
        key: 'live_cell_count',
        value: '1350000',
        units: 'cells/ml',
        created_at: Time.utc(2020, 2, 3, 4, 5, 6)
      )
    end
    let(:concentration_result) do
      create(
        :qc_result_concentration,
        created_at: Time.utc(2020, 11, 12, 13, 14, 15) # Latest of all the creation times
      )
    end

    context 'when well has a single concentration result' do
      let(:well) { create(:well, qc_results: [concentration_result]) }

      it 'returns nil' do
        expect(well.latest_live_cell_count).to be_nil
      end
    end

    context 'when well has a single cell count result' do
      let(:well) { create(:well, qc_results: [earlier_live_cell_count]) }

      it 'returns the correct QC result' do
        expect(well.latest_live_cell_count).to be(earlier_live_cell_count)
      end
    end

    context 'when well has a two concentration results in date order' do
      let(:well) { create(:well, qc_results: [earlier_live_cell_count, later_live_cell_count]) }

      it 'returns the later QC result by creation date' do
        expect(well.latest_live_cell_count).to be(later_live_cell_count)
      end
    end

    context 'when well has a two concentration results in reverse date order' do
      let(:well) { create(:well, qc_results: [later_live_cell_count, earlier_live_cell_count]) }

      it 'returns the later QC result by creation date' do
        expect(well.latest_live_cell_count).to be(later_live_cell_count)
      end
    end

    context 'when well has a mixed concentration result' do
      let(:well) do
        create(:well, qc_results: [concentration_result, later_live_cell_count, earlier_live_cell_count])
      end

      it 'returns the later QC result for live cell count' do
        expect(well.latest_live_cell_count).to be(later_live_cell_count)
      end
    end
  end

  describe '#latest_total_cell_count' do
    let(:earlier_total_cell_count) do
      create(
        :qc_result,
        key: 'total_cell_count',
        value: '1000000',
        units: 'cells/ml',
        created_at: Time.utc(2020, 1, 2, 3, 4, 5)
      )
    end
    let(:later_total_cell_count) do
      create(
        :qc_result,
        key: 'total_cell_count',
        value: '1350000',
        units: 'cells/ml',
        created_at: Time.utc(2020, 2, 3, 4, 5, 6)
      )
    end
    let(:concentration_result) do
      create(
        :qc_result_concentration,
        created_at: Time.utc(2020, 11, 12, 13, 14, 15) # Latest of all the creation times
      )
    end

    context 'when well has a single concentration result' do
      let(:well) { create(:well, qc_results: [concentration_result]) }

      it 'returns nil' do
        expect(well.latest_total_cell_count).to be_nil
      end
    end

    context 'when well has a single cell count result' do
      let(:well) { create(:well, qc_results: [earlier_total_cell_count]) }

      it 'returns the correct QC result' do
        expect(well.latest_total_cell_count).to be(earlier_total_cell_count)
      end
    end

    context 'when well has a two concentration results in date order' do
      let(:well) { create(:well, qc_results: [earlier_total_cell_count, later_total_cell_count]) }

      it 'returns the later QC result by creation date' do
        expect(well.latest_total_cell_count).to be(later_total_cell_count)
      end
    end

    context 'when well has a two concentration results in reverse date order' do
      let(:well) { create(:well, qc_results: [later_total_cell_count, earlier_total_cell_count]) }

      it 'returns the later QC result by creation date' do
        expect(well.latest_total_cell_count).to be(later_total_cell_count)
      end
    end

    context 'when well has a mixed concentration result' do
      let(:well) do
        create(:well, qc_results: [concentration_result, later_total_cell_count, earlier_total_cell_count])
      end

      it 'returns the later QC result for total cell count' do
        expect(well.latest_total_cell_count).to be(later_total_cell_count)
      end
    end
  end
end

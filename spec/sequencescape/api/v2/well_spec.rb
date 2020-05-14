# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Well do
  describe '#contains_control?' do
    let(:well) { create :v2_well }

    context 'with no control' do
      it 'returns false' do
        expect(well.contains_control?).to eq(false)
      end
    end

    context 'with control' do
      before do
        well.aliquots[0].sample.control = true
      end

      it 'returns true' do
        expect(well.contains_control?).to eq(true)
      end
    end
  end

  describe '#control_info_formatted' do
    let(:well) { create :v2_well }

    before do
      well.aliquots[0].sample.control = true
    end

    context 'with no control' do
      before do
        well.aliquots[0].sample.control = false
      end

      it 'returns nil' do
        expect(well.control_info_formatted).to be_nil
      end
    end

    context 'with positive control' do
      before do
        well.aliquots[0].sample.control_type = 'positive'
      end

      it 'is correctly formatted' do
        expect(well.control_info_formatted).to eq('+')
      end
    end

    context 'with negative control' do
      before do
        well.aliquots[0].sample.control_type = 'negative'
      end

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
end

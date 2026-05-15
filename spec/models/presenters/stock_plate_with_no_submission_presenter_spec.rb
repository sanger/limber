# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::StockPlateWithNoSubmissionPresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:labware) { create(:stock_plate) }

  describe '#allow_new_submission?' do
    it 'allows creation of new submissions' do
      expect(presenter.allow_new_submission?).to be true
    end
  end

  describe '#state' do
    it 'always returns passed' do
      expect(presenter.state).to eq('passed')
    end

    it 'is never pending, so the stock validator is never triggered' do
      expect(presenter.pending?).to be false
    end
  end

  describe '#input_barcode' do
    it 'returns the human barcode of the labware' do
      expect(presenter.input_barcode).to eq(labware.human_barcode)
    end
  end

  describe 'validation' do
    it 'is valid without any errors' do
      expect(presenter.valid?).to be true
    end

    it 'does not have any errors' do
      expect(presenter.errors).to be_empty
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

class SomeStockPlates
  def initialize(stock_plates)
    @stock_plates = stock_plates
  end

  def where(_arg)
    @stock_plates
  end
end

RSpec.describe Sequencescape::Api::V2::Tube do
  subject(:tube) { create :v2_tube, barcode_number: 12_345 }

  it { is_expected.to_not be_plate }
  it { is_expected.to be_tube }

  describe '#stock plate' do
    let(:stock_plates)          { create_list(:v2_stock_plate, 4) }
    let(:tube_with_ancestors)   { create :v2_tube, barcode_number: 12_345, ancestors: stock_plates }

    # I know this is a real hack but all we need to know is whether
    # it returns the last stock plate
    # I am not going to fumble about trying to recreate the whole pipeline
    it 'should return the last plate' do
      allow(tube_with_ancestors).to receive(:ancestors).and_return(SomeStockPlates.new(stock_plates))
      expect(tube_with_ancestors.stock_plate).to eq(stock_plates.last)
    end
  end
end

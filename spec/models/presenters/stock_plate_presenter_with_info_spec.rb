# frozen_string_literal: true
#
require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::StockPlatePresenterWithInfo do
  let(:labware) { create :v2_stock_plate }

  subject { Presenters::StockPlatePresenterWithInfo.new(labware:) }

  let(:barcode_string) { labware.human_barcode }

  it_behaves_like 'a stock presenter'

  it 'initializes with informational messages' do
    expected_messages = [
      "Please ensure you use the CITE-seq-compatible primer when working with 'LRC GEM-X 5p GEMs Input CITE' plates"
    ]
    expect(subject.info_messages).to match_array(expected_messages)
  end
end

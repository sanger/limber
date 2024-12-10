# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::StockPlatePresenter do
  let(:labware) { create :v2_stock_plate }

  subject { Presenters::StockPlatePresenter.new(labware:) }

  let(:barcode_string) { labware.human_barcode }

  it_behaves_like 'a stock presenter'
end

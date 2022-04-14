# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::StockPlatePresenter do
  has_a_working_api

  let(:labware) { create :v2_stock_plate }

  subject { Presenters::StockPlatePresenter.new(api: api, labware: labware) }

  let(:barcode_string) { 'DN2T' }

  it_behaves_like 'a stock presenter'
end

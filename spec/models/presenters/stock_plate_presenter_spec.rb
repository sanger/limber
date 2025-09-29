# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::StockPlatePresenter do
  subject { described_class.new(labware:) }

  let(:labware) { create :stock_plate }

  let(:barcode_string) { labware.human_barcode }

  it_behaves_like 'a stock presenter'
end

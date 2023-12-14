# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::FailableStockPlatePresenter do
  has_a_working_api

  let(:labware) { create :v2_stock_plate }

  subject { Presenters::FailableStockPlatePresenter.new(api: api, labware: labware) }

  let(:barcode_string) { 'DN2T' }

  it_behaves_like 'a stock presenter'

  it 'allows well failure in passed state' do
    expect(labware.state).to eq('passed')
    expect(subject.well_failing_applicable?).to be true
  end
end

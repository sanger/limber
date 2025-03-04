# frozen_string_literal: true
#
require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::StockPlatePresenter do
  let(:labware) do
    build :v2_stock_plate,
          receptacle: receptacle,
          purpose: purpose,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 6,
          created_at: '2016-10-19 12:00:00 +0100'
  end

  let!(:purpose_config) { create(:stock_plate_with_info_config, uuid: 'stock-plate-purpose-uuid') }
  let(:purpose) { create :v2_purpose, name: purpose_name, uuid: purpose_uuid }
  let(:purpose_name) { 'Limber example purpose' }
  let(:purpose_uuid) { 'example-purpose-uuid' }
  let(:labware) { create :v2_stock_plate }

  subject { Presenters::StockPlatePresenter.new(labware:) }

  let(:barcode_string) { labware.human_barcode }

  it_behaves_like 'a stock presenter'

  it 'initializes with informational messages' do
    expect(subject.info_messages).to match_array(['Test message'])
  end
end

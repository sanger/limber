# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::FinalTubePresenter do
  let(:labware) do
    build :v2_tube, purpose_name: purpose_name, state: state, barcode_number: 6, created_at: '2016-10-19 12:00:00 +0100'
  end

  before { create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid') }

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'NT6T <em>3980000006844</em>'],
      ['Tube type', purpose_name],
      ['Current tube state', state],
      ['Input plate barcode', labware.stock_plate.human_barcode],
      ['Created on', '2016-10-19']
    ]
  end
  let(:sidebar_partial) { 'default' }

  subject { Presenters::FinalTubePresenter.new(labware:) }

  it_behaves_like 'a labware presenter'
end

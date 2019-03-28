# frozen_string_literal: true

require 'rails_helper'
require 'presenters/tube_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TubePresenter do
  has_a_working_api

  let(:labware) do
    build :v2_multiplexed_library_tube,
          purpose_name: purpose_name,
          state: state,
          barcode_number: 6,
          created_at: '2016-10-19 12:00:00 +0100'
  end

  before do
    create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid')
  end

  let(:purpose_name) { 'Limber example purpose' }
  let(:title) { purpose_name }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      ['Barcode', 'NT6T <em>3980000006844</em>'],
      ['Tube type', purpose_name],
      ['Current tube state', state],
      ['Input plate barcode', 'DN2T <em>1220000002845</em>'],
      ['Created on', '2016-10-19']
    ]
  end

  subject do
    Presenters::TubePresenter.new(
      api: api,
      labware: labware
    )
  end

  it_behaves_like 'a labware presenter'
end

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TagPlate384Presenter do
  before { create :tag_plate_384_purpose_config }

  let(:date_format) { /\A\s?\d{1,2}-[A-Z]{3}-\d{4}\z/ } # e.g., ' 4 JUL 2023' or '24 JUL 2023'
  let(:purpose_name) { 'Tag Plate - 384' }
  let(:purpose) { create :purpose, name: purpose_name }
  let(:labware) { create :plate, purpose: purpose, size: 384, stock_plate: nil }
  let(:presenter) { described_class.new(labware:) }

  it 'can be looked up for labware' do
    expect(Presenters.lookup_for(labware)).to be(described_class)
  end

  it 'returns label with correct attributes' do
    attributes = presenter.label.attributes
    expect(attributes[:top_left]).to match(date_format)
    expect(attributes[:bottom_left]).to eq(labware.barcode.human)
    expect(attributes[:top_right]).to eq labware.workline_identifier
    expect(attributes[:bottom_right]).to eq [labware.role, labware.purpose_name].compact.join(' ')
    expect(attributes[:barcode]).to eq labware.barcode.human
  end
end

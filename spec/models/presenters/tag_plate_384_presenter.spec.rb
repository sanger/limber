# frozen_string_literal: true

RSpec.describe Presenters::TagPlate384Presenter do
  has_a_working_api

  let(:labware) { create :v2_plate, purpose_name: 'Tag Plate - 384' }
end

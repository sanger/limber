require 'rails_helper'
#require 'presenters/concentration_binned_plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::CardinalPoolsPlatePresenter, cardinal: true do
  has_a_working_api
end
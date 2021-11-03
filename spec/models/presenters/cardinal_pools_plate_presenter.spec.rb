# frozen_string_literal: true

require 'rails_helper'
require 'presenters/cardinal_pools_plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::CardinalPoolsPlatePresenter do
  has_a_working_api
end

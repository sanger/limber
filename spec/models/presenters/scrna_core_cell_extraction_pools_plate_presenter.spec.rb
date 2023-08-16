# frozen_string_literal: true

require 'rails_helper'
require 'presenters/scrna_core_cell_extraction_pools_plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::SCRNACoreCellExtractionPoolsPlatePresenter do
  has_a_working_api
end

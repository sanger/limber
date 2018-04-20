# frozen_string_literal: true

module Presenters::LibraryPoolCsv
  extend ActiveSupport::Concern

  WellConc = Struct.new(:name, :concentration, :pick, :pool)

  # Yields information for the show_extended.csv
  def each_well_and_concentration
    labware.wells.each do |well|
      binding.pry
    end
  end
end

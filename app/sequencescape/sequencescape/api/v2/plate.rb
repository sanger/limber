# frozen_string_literal: true

class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  has_many :wells
  has_many :samples

  def wells_in_columns
    @wells_in_columns ||= wells.sort_by { |w| WellHelpers.well_coordinate(w.position['name']) }
  end
end

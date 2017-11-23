# frozen_string_literal: true

# Simple class to handle form input for searching
class OngoingPlate
  include ActiveModel::Model
  attr_accessor :plate_purposes, :show_my_plates_only, :include_used, :states

  def purpose_uuids
    plate_purposes.blank? ? Settings.purposes.keys : plate_purposes
  end

  def search_parameters
    {
      states: states || %w[pending started passed qc_complete failed cancelled],
      plate_purpose_uuids: purpose_uuids,
      show_my_plates_only: show_my_plates_only == '1',
      include_used: include_used == '1'
    }
  end
end

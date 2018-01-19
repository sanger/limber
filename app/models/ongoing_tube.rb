# frozen_string_literal: true

# Simple class to handle form input for searching
class OngoingTube
  include ActiveModel::Model
  attr_accessor :tube_purposes, :include_used, :states

  def purpose_uuids
    tube_purposes.presence || Settings.purposes.keys
  end

  def search_parameters
    {
      states: states || %w[pending started passed qc_complete failed cancelled],
      tube_purpose_uuids: purpose_uuids,
      include_used: include_used == '1'
    }
  end
end

# frozen_string_literal: true

# Handles validating the tubes are in the same heirarchy and then displaying
# the transfer volume required for manual transfer at a given molarity.
class Tubes::ValidatePairedTubesController < ApplicationController
  before_action :check_for_current_user!

  def index; end
end

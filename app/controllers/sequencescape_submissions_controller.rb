# frozen_string_literal: true

# Handles generation of submissions in Sequencescape
class SequencescapeSubmissionsController < ApplicationController
  include SequencescapeSubmissionBehaviour

  before_action :check_for_current_user!

  def create
    create_submission
    redirect_back_or_to :root
  end
end

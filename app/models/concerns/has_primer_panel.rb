# frozen_string_literal: true

# Add support for displaying information about
# primer panels
module HasPrimerPanel
  extend ActiveSupport::Concern
  included do
    delegate :primer_panel, to: :labware
  end

  #
  # The name of the primer panel specified
  # on the submission
  #
  # @return [String] The specified primer panel
  #
  def panel_name
    primer_panel.name
  end

  #
  # The pcr program that the user should use
  # based on the selected primer panel
  #
  # @return [String] The pcr program the user should select
  #
  def pcr_program
    primer_panel.program_name_for(stage)
  end

  #
  # Human readable duration of the PCR program
  #
  #
  # @return [String] Diration of the configured program, eg. 45 minutes
  #
  def pcr_duration
    "#{primer_panel.program_duration_for(stage)} minutes"
  end

  private

  # The configured PCR stage
  def stage
    purpose_config.fetch(:pcr_stage, :unknown_stage)
  end
end

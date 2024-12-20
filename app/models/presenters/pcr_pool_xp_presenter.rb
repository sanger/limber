# frozen_string_literal: true

module Presenters
  # PcrPoolXpPresenter
  # This class is responsible for presenting PCR Pool XP tube data.
  # It inherits from FinalTubePresenter and provides methods
  # to export data to Traction.
  class PcrPoolXpPresenter < FinalTubePresenter
    # Enables the export of the PCR Pool XP tube to Traction if tube is in passed state.
    def export_to_traction
      state == 'passed'
    end
  end
end

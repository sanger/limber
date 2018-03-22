# frozen_string_literal: true

# The state presents the library pass page for tagged assets
module Presenters::Statemachine
  module AllowsLibraryPassing
    def control_library_passing
      yield if tagged? && !suggest_library_passing?
    end

    def control_suggested_library_passing
      yield if tagged? && suggest_library_passing?
    end
  end
end

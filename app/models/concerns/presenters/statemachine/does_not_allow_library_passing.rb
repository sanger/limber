# frozen_string_literal: true

# The state never presents the library pass button
module Presenters::Statemachine
  module DoesNotAllowLibraryPassing
    def control_library_passing
      false
    end

    def control_suggested_library_passing
      false
    end
  end
end

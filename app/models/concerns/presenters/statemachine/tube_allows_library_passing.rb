# frozen_string_literal: true

# The state presents the library pass page for tagged assets
module Presenters::Statemachine
  # Currently tube passing does not depend on request types.
  # Which is good, because that information is a bit hard
  # to get to.
  module TubeAllowsLibraryPassing
    def control_library_passing
      false
    end

    def control_suggested_library_passing
      yield
    end
  end
end

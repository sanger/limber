# frozen_string_literal: true

# The state never presents the library pass button
module Presenters::Statemachine
  module DoesNotAllowLibraryPassing
    def allow_library_passing?
      false
    end
  end
end

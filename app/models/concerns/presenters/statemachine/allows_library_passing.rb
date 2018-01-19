# frozen_string_literal: true

# The state presents the library pass page for tagged assets
module Presenters::Statemachine
  module AllowsLibraryPassing
    def allow_library_passing?
      tagged?
    end
  end
end

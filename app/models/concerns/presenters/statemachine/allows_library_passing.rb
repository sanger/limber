# frozen_string_literal: true

# The state presents the library pass page for tagged assets
module Presenters::Statemachine
  module AllowsLibraryPassing # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern

    included do
      def control_library_passing
        yield if libraries_passable? && !suggest_library_passing?
      end

      def control_suggested_library_passing
        yield if libraries_passable? && suggest_library_passing?
      end
    end
  end
end

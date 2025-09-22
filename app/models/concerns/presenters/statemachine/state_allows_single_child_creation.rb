# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of a single child asset in this state
  module StateAllowsSingleChildCreation
    extend ActiveSupport::Concern

    included do
      def control_additional_creation
        yield if child_assets.blank?
      end
    end
  end
end

# frozen_string_literal: true

module LabwareCreators::SupportParent
  module TaggedPlateOnly # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern
    class_methods do
      def support_parent?(parent)
        parent.plate? && parent.tagged?
      end
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
  end
end

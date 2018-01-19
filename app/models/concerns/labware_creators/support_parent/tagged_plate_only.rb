# frozen_string_literal: true

module LabwareCreators::SupportParent
  module TaggedPlateOnly
    extend ActiveSupport::Concern
    class_methods do
      def support_parent?(parent)
        parent.is_a?(Limber::Plate) && parent.tagged?
      end
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
  end
end

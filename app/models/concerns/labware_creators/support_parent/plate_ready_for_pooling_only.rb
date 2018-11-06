# frozen_string_literal: true

module LabwareCreators::SupportParent
  module PlateReadyForPoolingOnly
    extend ActiveSupport::Concern
    class_methods do
      def support_parent?(parent)
        parent.plate? && parent.tagged? && parent.ready_for_automatic_pooling?
      end
    end

    def parent
      @parent ||= api.plate.find(parent_uuid)
    end
  end
end

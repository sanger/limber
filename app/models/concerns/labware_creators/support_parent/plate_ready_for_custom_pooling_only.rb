# frozen_string_literal: true

module LabwareCreators::SupportParent
  module PlateReadyForCustomPoolingOnly # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern
    class_methods do
      def support_parent?(parent)
        parent.plate? && parent.tagged? && parent.ready_for_custom_pooling?
      end
    end

    def parent
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

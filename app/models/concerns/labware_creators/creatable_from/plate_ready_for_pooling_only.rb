# frozen_string_literal: true

module LabwareCreators::CreatableFrom
  module PlateReadyForPoolingOnly # rubocop:todo Style/Documentation
    extend ActiveSupport::Concern
    class_methods do
      def creatable_from?(parent)
        parent.plate? && parent.tagged? && parent.ready_for_automatic_pooling?
      end
    end

    def parent
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

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
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

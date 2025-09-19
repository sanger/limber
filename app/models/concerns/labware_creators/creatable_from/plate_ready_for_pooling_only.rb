# frozen_string_literal: true

module LabwareCreators::CreatableFrom
  # Only plates with tags and that are ready for automatic pooling are suitable parents for this creator.
  #
  # This uses `.creatable_from?` to determine whether we should render the link to create a child.
  module PlateReadyForPoolingOnly
    extend ActiveSupport::Concern

    class_methods do
      def creatable_from?(parent)
        parent.plate? && parent.tagged? && parent.ready_for_automatic_pooling?
      end
    end

    def parent
      return @parent if defined?(@parent)

      @parent = Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

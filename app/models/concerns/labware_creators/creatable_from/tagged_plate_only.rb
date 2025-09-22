# frozen_string_literal: true

module LabwareCreators::CreatableFrom
  # Only plates with tags are suitable parents for this creator.
  #
  # This uses `.creatable_from?` to determine whether we should render the link to create a child.
  module TaggedPlateOnly
    extend ActiveSupport::Concern

    class_methods do
      def creatable_from?(parent)
        parent.plate? && parent.tagged?
      end
    end

    def parent
      return @parent if defined?(@parent)

      @parent = Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

# frozen_string_literal: true

module LabwareCreators::CreatableFrom
  # Only plates are suitable parents for this creator.
  #
  # This uses `.creatable_from?` to determine whether we should render the link to create a child.
  module PlateOnly
    extend ActiveSupport::Concern

    class_methods do
      def creatable_from?(parent)
        parent.plate?
      end
    end

    def parent
      return @parent if defined?(@parent)

      @parent = Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end
  end
end

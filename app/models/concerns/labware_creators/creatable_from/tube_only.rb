# frozen_string_literal: true

module LabwareCreators::CreatableFrom
  # Only tubes are suitable parents for this creator.
  #
  # This uses `.creatable_from?` to determine whether we should render the link to create a child.
  module TubeOnly
    extend ActiveSupport::Concern

    class_methods do
      def creatable_from?(parent)
        parent.tube?
      end
    end

    def parent
      @parent ||= Sequencescape::Api::V2::Tube.find_by(uuid: parent_uuid)
    end
  end
end

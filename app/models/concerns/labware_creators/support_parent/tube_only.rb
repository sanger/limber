# frozen_string_literal: true

module LabwareCreators::SupportParent
  # Adds a class method which flags only tubes as suitable parents
  # This is used to work out is we should render the link
  module TubeOnly
    extend ActiveSupport::Concern
    class_methods do
      def support_parent?(parent)
        parent.tube?
      end
    end

    def parent
      @parent ||= api.tube.find(parent_uuid)
    end
  end
end

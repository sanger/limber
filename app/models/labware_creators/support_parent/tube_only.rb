# frozen_string_literal: true

module LabwareCreators::SupportParent
  # Adds a class method which flags only tubes as suitable parents
  # This is used to work out is we should render the link
  module TubeOnly
    def support_parent?(parent)
      parent.is_a?(Sequencescape::Tube)
    end
  end
end

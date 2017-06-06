# frozen_string_literal: true

module LabwareCreators::SupportParent
  module TaggedPlateOnly
    def support_parent?(parent)
      parent.is_a?(Limber::Plate) && parent.tagged?
    end
  end
end

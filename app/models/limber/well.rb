# frozen_string_literal: true

class Limber::Well < Sequencescape::Well # rubocop:todo Style/Documentation
  def suboptimal?
    aliquots.any?(&:suboptimal)
  end
end

# frozen_string_literal: true

class Limber::Well < Sequencescape::Well
  def suboptimal?
    aliquots.any?(&:suboptimal)
  end
end

class Limber::Well < Sequencescape::Well
  def suboptimal?
    aliquots.any? { |a| a.suboptimal }
  end
end

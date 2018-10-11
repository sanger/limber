# frozen_string_literal: true

# Groups tubes with the wells that get transferred into them
# Used by the plate presenter to ensure consistent colour-coding
class Presenters::TubesWithSources
  def self.build(wells:, pools:)
    wells.each_with_object({}) do |well, store|
      well.downstream_tubes.each do |tube|
        store[tube] ||= new(tube, pools)
        store[tube] << well
      end
    end.values
  end

  attr_reader :tube

  def initialize(tube, pools)
    @tube = tube
    @pools = pools
    @sources = []
  end

  def <<(well)
    @sources << well
  end

  # Returns the pool id based on the shared submission between the wells
  def pool_id
    @sources.map(&:submission_ids)
            .reduce { |common_ids, current_ids| common_ids & current_ids }
            .first
  end

  def pool_index
    @pools.pool_index(pool_id)
  end

  def source_locations
    @sources.map(&:location)
  end

  def pool_size
    @sources.sum { |well| well.aliquots.count }
  end

  delegate_missing_to :tube
end

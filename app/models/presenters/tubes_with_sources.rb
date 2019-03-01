# frozen_string_literal: true

# Groups tubes with the wells that get transferred into them
# Used by the plate presenter to ensure consistent colour-coding
# and annotation with source well information
class Presenters::TubesWithSources
  # Wrapper for the tube collection array
  class Collection
    attr_reader :array

    def initialize(array)
      @array = array
    end

    def tubes?
      @array.present?
    end

    def tube_labels
      # Optimization: To avoid needing to load in the tube aliquots, we use the transfers into the
      # tube to work out the pool size. This information is already available. Two values are different
      # for ISC though. TODO: MUST RE-JIG
      @array.map { |tube| Labels::TubeLabel.new(tube, pool_size: tube.pool_size) }
    end

    delegate_missing_to :array
  end

  def self.build(wells:, pools:)
    Collection.new(wells.each_with_object({}) do |well, store|
      well.downstream_tubes.each do |tube|
        store[tube] ||= new(tube, pools)
        store[tube] << well
      end
    end.values)
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

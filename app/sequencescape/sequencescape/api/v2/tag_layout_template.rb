# frozen_string_literal: true

# tag layout template resource
class Sequencescape::Api::V2::TagLayoutTemplate < Sequencescape::Api::V2::Base
  has_one :tag_group
  has_one :tag2_group, class_name: 'TagGroup'

  def dual_index?
    tag2_group.present?
  end

  # Performs the coercion of this instance so that it behaves appropriately given the direction
  # and walking algorithm information.
  def coerce
    extend("limber/tag_layout_template/in_#{direction.gsub(/\s+/, '_')}s".camelize.constantize)
    extend("limber/tag_layout_template/walk_#{walking_by.gsub(/\s+/, '_')}".camelize.constantize)
  rescue NameError => e
    Rails.logger.warn("Unrecognised layout options: #{e.message}")
    extend Unsupported
  end

  # This returns an array of well location to pool pairs.  The 'walker' is responsible for actually doing the walking
  # of the wells that are acceptable, and it calls back with the location of the well being processed.
  def group_wells(plate)
    well_to_pool = plate.wells.each_with_object({}) { |well, store| store[well.location] = well.pool_id }

    # We assume that if a well is unpooled then it is in the same pool as the previous pool.
    prior_pool = nil
    callback =
      lambda do |row_column|
        prior_pool = pool = well_to_pool[row_column] || prior_pool # or next
        well_empty = well_to_pool[row_column].nil?
        well = pool.nil? ? nil : row_column
        [well, pool, well_empty] # Triplet: [ A1, pool_id, well_empty ]
      end
    yield(callback)
  end
  private :group_wells

  def tag_ids
    tag_group.tags.map { |t| t['index'].to_i }.sort
  end
  private :tag_ids
end

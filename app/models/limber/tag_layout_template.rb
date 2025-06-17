# frozen_string_literal: true

class Limber::TagLayoutTemplate # rubocop:todo Style/Documentation
  # Performs the coercion of this instance so that it behaves appropriately given the direction
  # and walking algorithm information.
  attribute_reader :name, :direction, :walking_by
  belongs_to :plate, class_name: 'Plate'
  composed_of :tag_group, class_name: 'Tag::Group'
  composed_of :tag2_group, class_name: 'Tag::Group'

  has_create_action resource: 'tag_layout'

  def dual_index?
    tag2_group.present?
  end

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
    tag_group.tags.keys.map!(&:to_i).sort
  end
  private :tag_ids
end

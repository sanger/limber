# frozen_string_literal: true

require_dependency './lib/repeated_state_change_error'

module LabwareCreators
  # Duplicate of TaggedPlate Creator to allow configuration to be built independently
  # of behaviour.
  class CustomTaggedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_reader :child, :tag_plate
    attr_accessor :tag_plate_barcode, :tag_layout

    self.page = 'custom_tagged_plate'
    self.attributes += [
      :tag_plate_barcode,
      {
        tag_plate: %i[asset_uuid template_uuid],
        tag_layout: %i[user plate tag_group tag2_group direction walking_by initial_tag substitutions tags_per_well]
      }
    ]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware
    delegate :used?, :list, :names, to: :tag_plates, prefix: true

    def tag_plate=(params)
      @tag_plate = OpenStruct.new(params)
    end

    def initialize(*args, &block)
      super
      parent.populate_wells_with_pool
    end

    def create_plate!
      @child = api.pooled_plate_creation.create!(
        child_purpose: purpose_uuid,
        user: user_uuid,
        parents: [parent_uuid, tag_plate.asset_uuid]
      ).child

      transfer_material_from_parent!(@child.uuid)

      yield(@child.uuid) if block_given?

      begin
        unless tag_plate.asset_uuid.blank? || tag_plate.state == 'exhausted'
          api.state_change.create!(
            user: user_uuid,
            target: tag_plate.asset_uuid,
            reason: 'Used in Library creation',
            target_state: 'exhausted'
          )
        end
      rescue RepeatedStateChangeError => exception
        # Plate is already exhausted, the user is probably processing two plates
        # at the same time
        Rails.logger.warn(exception.message)
      end

      true
    end

    def requires_tag2?
      parent.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
    end

    def pool_index(_pool_index)
      nil
    end

    private

    def transfer_hash
      WellHelpers.stamp_hash(parent.size)
    end

    def tag_plates
      @tag_plates ||= LabwareCreators::Tagging::TagCollection.new(api, labware, purpose_uuid)
    end

    def create_labware!
      create_plate! do |plate_uuid|
        api.tag_layout.create!(tag_layout.merge(plate: plate_uuid))
      end
    end
  end
end

# frozen_string_literal: true

require_dependency './lib/repeated_state_change_error'

module LabwareCreators
  # Duplicate of TaggedPlate Creator to allow configuration to be built independently
  # of behaviour.
  class CustomTaggedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_reader :child, :tag_plate
    attr_accessor :tag_layout

    self.page = 'custom_tagged_plate'
    self.attributes += [
      {
        tag_plate: %i[asset_uuid template_uuid state],
        tag_layout: [
          :user, :plate, :tag_group, :tag2_group, :direction, :walking_by, :initial_tag, :tags_per_well, { substitutions: {} }
        ]
      }
    ]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware
    delegate :used?, :list, :names, to: :tag_plates, prefix: true

    def tag_plate=(params)
      @tag_plate = OpenStruct.new(params)
    end

    def initialize(*args, &block)
      super
      parent.populate_wells_with_pool
    end

    # rubocop:todo Metrics/MethodLength
    def create_plate! # rubocop:todo Metrics/AbcSize
      @child = api.pooled_plate_creation.create!(
        child_purpose: purpose_uuid,
        user: user_uuid,
        parents: [parent_uuid, tag_plate.asset_uuid].reject(&:blank?)
      ).child

      transfer_material_from_parent!(@child.uuid)

      yield(@child.uuid) if block_given?

      return true if tag_plate.asset_uuid.blank? || tag_plate.state == 'exhausted'

      begin
        api.state_change.create!(
          user: user_uuid,
          target: tag_plate.asset_uuid,
          reason: 'Used in Library creation',
          target_state: 'exhausted'
        )
      rescue RepeatedStateChangeError => e
        # Plate is already exhausted, the user is probably processing two plates
        # at the same time
        Rails.logger.warn(e.message)
      end

      true
    end
    # rubocop:enable Metrics/MethodLength

    def requires_tag2?
      parent.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
    end

    def pool_index(_pool_index)
      nil
    end

    #
    # The tags per well number.
    # In most cases this will be the default 1 unless overriden in the purposes yml
    # e.g. for Chromium plates in bespoke it is 4
    #
    # @return [<Number] The number of tags per well.
    #
    def tags_per_well
      purpose_config.fetch(:tags_per_well, 1)
    end

    private

    def tag_layout_attributes
      tag_layout.reject { |_key, value| value.blank? }
    end

    def transfer_hash
      WellHelpers.stamp_hash(parent.size)
    end

    def tag_plates
      @tag_plates ||= LabwareCreators::Tagging::TagCollection.new(api, labware, purpose_uuid)
    end

    def create_labware!
      create_plate! do |plate_uuid|
        api.tag_layout.create!(tag_layout_attributes.merge(plate: plate_uuid, user: user_uuid))
      end
    end
  end
end

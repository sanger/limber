# frozen_string_literal: true

require_dependency './lib/repeated_state_change_error'

module LabwareCreators
  # Duplicate of TaggedPlate Creator to allow configuration to be built independently
  # of behaviour.
  class CustomTaggedPlate < Base
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateOnly
    include LabwareCreators::TaggedPlateBehaviour

    attr_reader :child, :tag_plate
    attr_accessor :tag_layout

    self.page = 'custom_tagged_plate'
    # Used for permitting all the parameters in the controller
    self.attributes += [
      {
        tag_plate: %i[asset_uuid template_uuid state],
        tag_layout: [
          :user_uuid,
          :plate_uuid,
          :tag_group_uuid,
          :tag2_group_uuid,
          :direction,
          :walking_by,
          :initial_tag,
          :tags_per_well,
          { substitutions: {} }
        ]
      }
    ]
    class_attribute :should_populate_wells_with_pool

    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    def tag_plate=(params)
      @tag_plate = OpenStruct.new(params) # rubocop:todo Style/OpenStructUse
    end

    def initialize(*args, &)
      super
      parent.assign_pools_to_wells
    end

    def create_plate! # rubocop:todo Metrics/AbcSize
      @child =
        Sequencescape::Api::V2::PooledPlateCreation.create!(
          child_purpose_uuid: purpose_uuid,
          parent_uuids: [parent_uuid, tag_plate.asset_uuid].compact_blank,
          user_uuid: user_uuid
        ).child

      transfer_material_from_parent!(@child.uuid)

      yield(@child.uuid) if block_given?

      return true if tag_plate.asset_uuid.blank? || tag_plate.state == 'exhausted'

      begin
        flag_tag_plate_as_exhausted
      rescue RepeatedStateChangeError => e
        # Plate is already exhausted, the user is probably processing two plates
        # at the same time
        Rails.logger.warn(e.message)
      end
      true
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

    #
    # The adapter type name filter for limiting the tag group list drop downs on the custom tagging
    # screen. In most cases this will not be present in the purposes yml and is not required.
    # e.g. to just show tag groups with Chromium adapter types it is 'Chromium'
    #
    # @return [<String] The name of the adapter type.
    #
    def tag_group_adapter_type_name_filter
      purpose_config.fetch(:tag_group_adapter_type_name_filter, nil)
    end

    # Define the filters method for the CustomTaggedPlate labware creator for
    # compatibility with the PartialWellFilteredCustomTaggedPlateCreator. The
    # filters is the pipeline filters for the latter labware creator.
    #
    # @return [Hash] the default empty filters
    def filters
      {}
    end

    private

    def tag_layout_attributes
      tag_layout.compact_blank
    end

    def create_labware!
      create_plate! do |plate_uuid|
        Sequencescape::Api::V2::TagLayout.create!(tag_layout_attributes.merge(plate_uuid:, user_uuid:))
      end
    end
  end
end

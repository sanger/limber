# frozen_string_literal: true

module LabwareCreators
  # Handles transfer of material into a pre-existing tag plate, created via
  # Gatekeeper. It performs a few actions:
  # 1) Updates the state of the tag plate to flag the resource as exhausted
  #    (Tag plates delegate their state to the qcable)
  # 2) Converts the tag plate to a new plate purpose
  # 3) Transfers the material from the parent, into the converted tag plate (Now the child)
  # 4) Applies the tag template that was associated with the tag plate
  class TaggedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_reader :child, :tag_plate
    attr_accessor :tag_plate_barcode

    self.page = 'tagged_plate'
    self.attributes += [
      :tag_plate_barcode,
      { tag_plate: %i[asset_uuid template_uuid] }
    ]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    # If I call `tag_plates_used?`, it calls `tag_plates.used?`
    # where `tag_plates` is a method in this class, returning an instance of TagCollection
    # similar for `list` and `names`
    delegate :used?, :list, :names, to: :tag_plates, prefix: true

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def initialize(*args, &block)
      super
      parent.populate_wells_with_pool
    end

    # rubocop:todo Metrics/MethodLength
    def create_plate! # rubocop:todo Metrics/AbcSize
      transfer_material_from_parent!(tag_plate.asset_uuid)

      yield(tag_plate.asset_uuid) if block_given?

      api.state_change.create!(
        user: user_uuid,
        target: tag_plate.asset_uuid,
        reason: 'Used in Library creation',
        target_state: 'exhausted'
      )

      # Convert plate instead of creating it
      @child = api.plate_conversion.create!(
        target: tag_plate.asset_uuid,
        purpose: purpose_uuid,
        user: user_uuid,
        parent: parent_uuid
      ).target

      true
    end
    # rubocop:enable Metrics/MethodLength

    def requires_tag2?
      parent.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
    end

    #
    # Indicates if a UDI tag plate is required
    # UDI plates are:
    # Required if part of a pool already using UDI plates
    # Permitted, but not required in all other cases
    #
    # @return [Boolean] false: UDI plates are forbidden [Not currently used]
    #                    true: UDI plates are required
    #                    nil: UDI plates are permitted, but not required
    #
    def tag_plate_dual_index?
      requires_tag2? || nil
    end

    def help
      requires_tag2? ? 'dual_plate' : 'single'
    end

    def pool_index(_pool_index)
      nil
    end

    def enforce_same_template_within_pool?
      purpose_config.fetch(:enforce_same_template_within_pool, false)
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
        api.tag_layout_template.find(tag_plate.template_uuid).create!(
          plate: plate_uuid,
          user: user_uuid,
          enforce_uniqueness: requires_tag2?
        )
      end
    end
  end
end

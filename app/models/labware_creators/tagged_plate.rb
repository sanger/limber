# frozen_string_literal: true

# rubocop:todo Metrics/ClassLength
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

    attr_reader :child, :tag_plate, :tag2_tube
    attr_accessor :tag_plate_barcode, :tag2_tube_barcode

    self.page = 'tagged_plate'
    self.attributes += [
      :tag_plate_barcode, :tag2_tube_barcode,
      { tag_plate: %i[asset_uuid template_uuid], tag2_tube: %i[asset_uuid template_uuid] }
    ]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true
    validates :tag2_tube_barcode, :tag2_tube, presence: { if: :tag_tubes_used? }

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    # If I call `tag_plates_used?`, it calls `tag_plates.used?`
    # where `tag_plates` is a method in this class, returning an instance of TagCollection
    # similar for `list` and `names`
    delegate :used?, :list, :names, to: :tag_plates, prefix: true
    delegate :used?, :list, :names, to: :tag_tubes, prefix: true

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def tag2_tube=(params)
      @tag2_tube = QcableObject.new(params[:asset_uuid], params[:template_uuid])
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
    # Returns an array of acceptable source of tag2. The rules are as follows:
    # - If we don't need a tag2, allow anything, it doesn't matter.
    # - If we've already started using one method, enforce it for the rest of the pool
    # - Otherwise, anything goes
    # Note: The order matters here, as pools tagged with tubes will still list plates
    # for the i5 (tag) tag.
    #
    # @return [Array<String>] An array of acceptable sources, 'plate' and/or 'tube'
    def acceptable_tag2_sources
      return ['tube'] if tag_tubes_used?
      return ['plate'] if tag_plates_used?

      %w[tube plate]
    end

    def tag2_field
      yield if allow_tag_tube?
    end

    def allow_tag_tube?
      acceptable_tag2_sources.include?('tube')
    end

    #
    # Indicates if a UDI tag plate is permitted/required
    # UDI plates are:
    # Required if part of a pool already using UDI plates
    # Forbidden if part of a pool using tubes
    # Permitted, but not required in all other cases
    #
    # @return [Boolean] false: UDI plates are forbidden
    #                    true: UDI plates are required
    #                    nil: UDI plates are permitted, but not required
    #
    def tag_plate_dual_index?
      return false if tag_tubes_used?
      return true if tag_plates_used? && requires_tag2?

      nil
    end

    def help
      requires_tag2? ? 'single' : "dual_#{acceptable_tag2_sources.join('_')}"
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

    def tag_tubes
      @tag_tubes ||= LabwareCreators::Tagging::Tag2Collection.new(api, labware)
    end

    # rubocop:todo Metrics/MethodLength
    def create_labware! # rubocop:todo Metrics/AbcSize
      create_plate! do |plate_uuid|
        api.tag_layout_template.find(tag_plate.template_uuid).create!(
          plate: plate_uuid,
          user: user_uuid,
          enforce_uniqueness: requires_tag2?
        )

        if tag2_tube_barcode.present?
          api.state_change.create!(
            user: user_uuid,
            target: tag2_tube.asset_uuid,
            reason: 'Used in Library creation',
            target_state: 'exhausted'
          )

          api.tag2_layout_template.find(tag2_tube.template_uuid).create!(
            source: tag2_tube.asset_uuid,
            plate: plate_uuid,
            user: user_uuid
          )
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end
# rubocop:enable Metrics/ClassLength

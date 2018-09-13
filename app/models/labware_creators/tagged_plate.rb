# frozen_string_literal: true

module LabwareCreators
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

    def create_plate!
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

    def requires_tag2?
      parent.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
    end

    #
    # Returns an array of acceptable source of tag2. The rules are as follows:
    # - If we don't need a tag2, allow anything, it doesn't matter.
    # - If we've already started using one method, enforce it for the rest of the pool
    # - Otherwise, anything goes
    # Note: The order matter here, as pools tagged with tubes will still list plates
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
      nil
    end

    def allow_tag_tube?
      acceptable_tag2_sources.include?('tube')
    end

    def tag_plate_dual_index?
      return false if tag_tubes_used?
      return true if tag_plates_used?
      nil
    end

    def help
      return 'single' unless requires_tag2?
      "dual_#{acceptable_tag2_sources.join('_')}"
    end

    private

    def transfer_material_from_parent!(child_uuid)
      transfer_template.create!(
        source: parent_uuid,
        destination: child_uuid,
        user: user_uuid,
        transfers: transfer_hash
      )
    end

    def transfer_hash
      WellHelpers.stamp_hash(parent.size)
    end

    def tag_plates
      @tag_plates ||= LabwareCreators::Tagging::TagCollection.new(api, labware, purpose_uuid)
    end

    def tag_tubes
      @tag_tubes ||= LabwareCreators::Tagging::Tag2Collection.new(api, labware)
    end

    def create_labware!
      create_plate! do |plate_uuid|
        api.tag_layout_template.find(tag_plate.template_uuid).create!(
          plate: plate_uuid,
          user: user_uuid
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
  end
end

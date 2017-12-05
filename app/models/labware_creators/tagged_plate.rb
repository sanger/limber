# frozen_string_literal: true

module LabwareCreators
  class TaggedPlate < Base
    include Form::CustomPage

    self.page = 'tagged_plate'
    self.attributes = %i[
      api purpose_uuid parent_uuid user_uuid
      tag_plate_barcode tag_plate
      tag2_tube_barcode tag2_tube
    ]

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true
    validates :tag2_tube_barcode, :tag2_tube, presence: { if: :requires_tag2? }

    delegate :height, :width, :size, to: :labware

    attr_reader :child

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      return nil if params.blank?
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def tag2_tube=(params)
      return nil if params.blank?
      @tag2_tube = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def initialize(*args, &block)
      super
      plate.populate_wells_with_pool
    end

    def substitutions
      @substitutions ||= {}
    end

    def tag_groups
      @tag_groups ||= LabwareCreators::Tagging::TagCollection.new(api, plate, purpose_uuid).available
    end

    def tag2s
      @tag2s ||= LabwareCreators::Tagging::Tag2Collection.new(api, plate).available
    end

    def tag2_names
      tag2s.values.map(&:name)
    end

    def create_plate!
      api.transfer_template.find(transfer_template_uuid).create!(
        source: parent_uuid,
        destination: tag_plate.asset_uuid,
        user: user_uuid
      )

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
      plate.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
    end

    def tag2_field
      yield if requires_tag2?
      nil
    end

    private

    def create_labware!
      create_plate! do |plate_uuid|
        api.tag_layout_template.find(tag_plate.template_uuid).create!(
          plate: plate_uuid,
          user: user_uuid,
          substitutions: substitutions.reject { |_, new_tag| new_tag.blank? }
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

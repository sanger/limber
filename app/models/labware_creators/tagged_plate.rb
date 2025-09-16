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
    include CreatableFrom::PlateOnly
    include LabwareCreators::TaggedPlateBehaviour

    attr_reader :child, :tag_plate
    attr_accessor :tag_plate_barcode

    self.page = 'tagged_plate'
    self.attributes += [:tag_plate_barcode, { tag_plate: %i[asset_uuid template_uuid] }]
    self.default_transfer_template_name = 'Custom pooling'

    # The TaggedPlate labware creator uses API V1 Plate as parent. The V1 Plate
    # has the populate_wells_with_pool method that assigns pools to wells using
    # its pools attribute. However, this is incompatible with the V2 API Plate.
    # The V2 plate does not have such a method and its pool attribute has a
    # different structure. The populate_wells_with_pool method is called in the
    # initialize method of the TaggedPlate labware creator on the parent plate.
    # This makes it difficult to subclass the labware creator and also use a V2
    # API plate as parent. If the class attribute should_populate_wells_with_pool
    # is set to false, it will not call the populate_wells_with_pool method on
    # the parent plate.

    class_attribute :should_populate_wells_with_pool
    self.should_populate_wells_with_pool = true # parent is a V1 plate

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def initialize(*args, &)
      super
      parent.assign_pools_to_wells
    end

    def create_plate!
      transfer_material_from_parent!(tag_plate.asset_uuid)

      yield(tag_plate.asset_uuid) if block_given?

      flag_tag_plate_as_exhausted

      # Convert plate instead of creating it.
      # Target returns the newly converted tag plate.
      @child = convert_tag_plate_to_new_purpose.target

      true
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

    #
    # Convert the tag plate to the new purpose.
    #
    # @return [Sequencescape::Api::V2::PlateConversion] The result of the conversion.
    #
    def convert_tag_plate_to_new_purpose
      Sequencescape::Api::V2::PlateConversion.create!(
        parent_uuid: parent_uuid,
        purpose_uuid: purpose_uuid,
        target_uuid: tag_plate.asset_uuid,
        user_uuid: user_uuid
      )
    end

    def create_labware!
      create_plate! do |plate_uuid|
        Sequencescape::Api::V2::TagLayout.create!(
          enforce_uniqueness: requires_tag2?,
          plate_uuid: plate_uuid,
          tag_layout_template_uuid: tag_plate.template_uuid,
          user_uuid: user_uuid
        )
      end
    end
  end
end

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
    include LabwareCreators::TaggedPlateBehaviour

    attr_reader :child, :tag_plate
    attr_accessor :tag_plate_barcode

    self.page = 'tagged_plate'
    self.attributes += [:tag_plate_barcode, { tag_plate: %i[asset_uuid template_uuid] }]
    self.default_transfer_template_name = 'Custom pooling'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def initialize(*args, &)
      super
      parent.populate_wells_with_pool
    end

    def create_plate!
      transfer_material_from_parent!(tag_plate.asset_uuid)

      yield(tag_plate.asset_uuid) if block_given?

      flag_tag_plate_as_exhausted

      # Convert plate instead of creating it
      # Target returns the newly converted tag plate
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
    # Convert the tag plate to the new purpose
    #
    # @return [Sequencescape::Api::PlateConversion] The conversion action
    #
    def convert_tag_plate_to_new_purpose
      api.plate_conversion.create!(
        target: tag_plate.asset_uuid,
        purpose: purpose_uuid,
        user: user_uuid,
        parent: parent_uuid
      )
    end

    def create_labware!
      create_plate! do |plate_uuid|
        # TODO: {Y24-190} Work out a way to call the `create!` method on TagLayoutTemplate model in Sequencescape
        #       using the V2 API. I think either we need to misuse the PATCH method with some kind of
        #       attributes telling Sequencescape to run the `create!` method, or we need to create a new
        #       endpoint associated with a TagLayoutTemplate that will run the `create!` method.
        api
          .tag_layout_template
          .find(tag_plate.template_uuid)
          .create!(plate: plate_uuid, user: user_uuid, enforce_uniqueness: requires_tag2?)
      end
    end
  end
end

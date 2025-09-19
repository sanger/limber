# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # Simply creates a new plate of the specified purpose and transfers material
  # across in a direct stamp. (ie. The location of a sample on the source plate
  # is the same as the location on the destination plate.)
  class StampedPlate < Base
    include CreatableFrom::PlateOnly

    self.default_transfer_template_name = 'Custom pooling'
    self.attributes += [{ filters: {} }]

    validates_nested :well_filter

    def parent
      return @parent if defined?(@parent)

      @parent = Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    def labware_wells
      parent.wells
    end

    private

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes(child_plate),
        user_uuid: user_uuid
      )
    end

    def transfer_request_attributes(child_plate)
      well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plate, additional_parameters) }
    end

    def request_hash(source_well, child_plate, additional_parameters)
      {
        source_asset: source_well.uuid,
        target_asset: child_plate.wells.detect { |child_well| child_well.location == source_well.location }&.uuid
      }.merge(additional_parameters)
    end
  end
end

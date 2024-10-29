# frozen_string_literal: true

# This module can be included to labware creators to add well filtering behaviour.
# It builds transfers as direct stamp, which should be overridden if necessary.
module LabwareCreators::WellFilterBehaviour
  extend ActiveSupport::Concern

  included do
    self.attributes += [{ filters: {} }]

    validates_nested :well_filter
  end

  def parent
    @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
  end

  def filters=(filter_parameters)
    well_filter.assign_attributes(filter_parameters)
  end

  def labware_wells
    parent.wells
  end

  def pipeline_filters
    pipeline = Settings.pipelines.active_pipelines_for(parent).find do |pipeline|
      pipeline.child_for(parent.purpose_name) == purpose_name
    end
    pipeline&.filters
  end

  private

  def well_filter
    @well_filter ||= LabwareCreators::WellFilter.new(creator: self)
  end

  def transfer_material_from_parent!(child_uuid)
    child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
    api.transfer_request_collection.create!(
      user: user_uuid,
      transfer_requests: transfer_request_attributes(child_plate)
    )
  end

  def transfer_request_attributes(child_plate)
    well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plate, additional_parameters) }
  end

  def request_hash(source_well, child_plate, additional_parameters)
    {
      'source_asset' => source_well.uuid,
      'target_asset' => child_plate.wells.detect { |child_well| child_well.location == source_well.location }&.uuid
    }.merge(additional_parameters)
  end
end

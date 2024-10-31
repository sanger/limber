# frozen_string_literal: true

# This module can be included to labware creators to add well filtering behaviour.
# It builds transfers as direct stamp, which should be overridden if necessary.
module LabwareCreators::WellFilterBehaviour
  extend ActiveSupport::Concern

  included do
    # Used for permitting the filters parameter in the controller
    self.attributes += [{ filters: {} }]

    validates_nested :well_filter

    # @!attribute [r] filters
    #   @return [Hash] the filters made available to the views such as custom page.
    attr_reader :filters
  end

  # Returns the parent plate of the labware creator using the uuid of the parent.
  #
  # @return [Sequencescape::Api::V2::Plate]
  def parent
    @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
  end

  # Assigns the filters on the creator and the well filter. The filters are as
  # specified in the pipeline configuration but values are always arrays, for
  # example, { request_type_key: ['example_request_type_key'], library_type: ['example_library_type']}
  #
  # They are passed by the creation controller to initialise the labware creator instance.
  #
  # @param [Hash] filter_parameters The parameters to assign to the filters.
  # @return [void]
  def filters=(filter_parameters)
    @filters = filter_parameters
    well_filter.assign_attributes(filter_parameters)
  end

  # Returns the wells of the parent plate. This is a call back method from the
  # well filter. The filtered wells are in the same order as returned by this
  # method.
  #
  # @return [Array<Sequencescape::Api::V2::Well>]
  def labware_wells
    parent.wells
  end

  private

  # Creates if not exists and returns the WellFilter instance associated with
  # the labware creator.
  #
  # @return [WellFilter] The WellFilter instance.
  def well_filter
    @well_filter ||= LabwareCreators::WellFilter.new(creator: self)
  end

  # Creates transfer requests from source wells to the destination plate in
  # Sequencescape.
  #
  # @param dest_uuid [String] The UUID of the destination plate.
  # @return [Boolean] Returns true if no exception is raised.
  def transfer_material_from_parent!(child_uuid)
    child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
    api.transfer_request_collection.create!(
      user: user_uuid,
      transfer_requests: transfer_request_attributes(child_plate)
    )
  end

  # Returns the attributes for transfer requests from the source wells to the
  # destination plate.
  #
  # @param dest_plate [Sequencescape::Api::V2::Plate] The destination plate.
  # @return [Array<Hash>] An array of hashes, each representing the attributes
  #   for a transfer request.
  def transfer_request_attributes(child_plate)
    well_filter.filtered.map { |well, additional_parameters| request_hash(well, child_plate, additional_parameters) }
  end

  # Returns a hash representing a transfer request from a source well to a
  # destination well. Additional parameters generated by the well filter are
  # merged into the request hash such as 'outer_request' and 'submission_id'.
  # This method assumes a direct stamp transfer i.e. A1 -> A1, B1 -> B1 etc.
  #
  # @param source_well [Sequencescape::Api::V2::Well] The source well.
  # @param dest_plate [Sequencescape::Api::V2::Plate] The destination plate.
  # @param additional_parameters [Hash] Additional parameters to include.
  # @return [Hash] A hash representing a transfer request.
  def request_hash(source_well, child_plate, additional_parameters)
    {
      'source_asset' => source_well.uuid,
      'target_asset' => child_plate.wells.detect { |child_well| child_well.location == source_well.location }&.uuid
    }.merge(additional_parameters)
  end
end
# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # This labware creator pools PBMC isolations with the same samples in pairs
  # (or configured number of source wells) per destination before cell counting
  # to reduce the number runs on Cellaca (cell counting). The robot transfer is
  # done from LRC Blood Bank to LRC PBMC Bank plate. Only the wells with passed
  # state will be transferred to the destination plate. The destination wells
  # are compressed to top left by column on the plate.
  class PooledWellsBySampleInGroups < Base
    include CreatableFrom::PlateOnly

    # Number of source wells with the same sample to be pooled.
    def number_of_source_wells
      @number_of_source_wells ||= purpose_config.dig(:creator_class, :args, :number_of_source_wells)
    end

    # Well filter with this object as the creator
    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # List of passed wells of the parent labware in column order. Used by well filter.
    def labware_wells
      source_plate.wells_in_columns.select(&:passed?)
    end

    # Parent plate using SS v2 API
    def source_plate
      return @source_plate if defined?(@source_plate)

      @source_plate = Sequencescape::Api::V2::Plate.find_by(uuid: parent.uuid)
    end

    # List of filtered wells for pooling.
    def parent_wells_for_pooling
      well_filter.filtered.map(&:first)
    end

    # List of pools to be created; index is the destination pool number; each pool is a list of source wells
    def build_pools
      parent_wells_for_pooling
        .group_by { |well| well.aliquots.first.sample.uuid }
        .flat_map { |_uuid, wells| wells.each_slice(number_of_source_wells).to_a }
    end

    # List of pools built from passed wells from parent plate
    def pools
      @pools ||= build_pools
    end

    # Object mapping source wells to destination wells for transfers
    def transfer_hash
      result = {}
      pools.each_with_index do |pool, index|
        dest_location = WellHelpers.well_at_column_index(index)
        pool.each do |source_well|
          source_location = source_well.location
          result[source_location] = { dest_locn: dest_location }
        end
      end
      result
    end

    # Well object at well location on plate
    def get_well_for_plate_location(plate, well_location)
      plate.wells.detect { |well| well.location == well_location }
    end

    # Attributes for transfer request from source_well to dest_plate
    def request_hash(source_well, dest_plate, additional_parameters)
      dest_location = transfer_hash[source_well.location][:dest_locn]
      {
        source_asset: source_well.uuid,
        target_asset: get_well_for_plate_location(dest_plate, dest_location)&.uuid,
        merge_equivalent_aliquots: true
      }.merge(additional_parameters)
    end

    # List of objects mapping source wells to destination wells
    def transfer_request_attributes(dest_plate)
      well_filter.filtered.filter_map do |source_well, additional_parameters|
        request_hash(source_well, dest_plate, additional_parameters)
      end
    end

    # Send the transfer request to SS
    def transfer_material_from_parent!(dest_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: dest_uuid)
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes(dest_plate),
        user_uuid: user_uuid
      )
      true
    end
  end
end

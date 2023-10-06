# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # This labware creator pools PBMC isolations in pairs (or configured number of
  # source wells per destination) before cell counting to reduce the number runs
  # on Celleca (cell counting). The robot transfer is done from LRC Blood Bank to
  # LRC PBMC Bank plate.
  class PooledWellsBySample < Base
    include SupportParent::PlateOnly

    # By default, source wells with the sample are pooled in pairs.
    DEFAULT_NUMBER_OF_SOURCE_WELLS = 2

    # Number of source wells with the same sample to be pooled.
    def number_of_source_wells
      purpose_config[:number_of_source_wells] || DEFAULT_NUMBER_OF_SOURCE_WELLS
    end

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    # Parent plate using SS v2 API
    def source_plate
      @source_plate ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent.uuid)
    end

    # List of passed wells from parent plate
    def passed_parent_wells
      source_plate.wells.select { |well| well.state == 'passed' }
    end

    # List of passed wells from parent plate in column order
    def parent_wells_in_colums
      passed_parent_wells.sort_by(&:coordinate)
    end

    # List of pools to be created; index is the destination pool number; each pool is a list of source wells
    def build_pools
      parent_wells_in_colums
        .group_by { |well| well.aliquots.first.sample.uuid }
        .flat_map { |_uuid, wells| wells.each_slice(number_of_source_wells).to_a }
    end

    # List of pools built from passed wells from parent plate
    def pools
      @pools ||= build_pools
    end

    # Object mapping source wells to destination wells for
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
    def request_hash(source_well, dest_plate)
      dest_location = transfer_hash[source_well.location][:dest_locn]
      {
        'source_asset' => source_well.uuid,
        'target_asset' => get_well_for_plate_location(dest_plate, dest_location)&.uuid,
        # 'submission' => submission,
        'merge_equivalent_aliquots' => true
      }
    end

    # List of objects mapping source wells to destination wells
    def transfer_request_attributes(dest_plate)
      passed_parent_wells.map { |source_well| request_hash(source_well, dest_plate) }
    end

    # Send the transfer request to SS
    def transfer_material_from_parent!(dest_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: dest_uuid)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(dest_plate)
      )
      true
    end
  end
end

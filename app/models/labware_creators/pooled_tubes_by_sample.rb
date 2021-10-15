# frozen_string_literal: true

require_dependency 'labware_creators/base'

module LabwareCreators
  # ...
  class PooledTubesBySample < Base
    include SupportParent::PlateOnly

    # loop through source wells, building hash by grouping based on sample uuid
    # each hash of samples will go into one destination tube
    # set parameter on transfer request collection (if that's where it is) to consolidate identical aliquots

    attr_reader :tube_transfer, :child_stock_tubes

    def create_labware!
      @child_stock_tubes = create_child_stock_tubes
      perform_transfers
      true
    end

    def perform_transfers
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes
      )
    end

    def create_child_stock_tubes
      api.specific_tube_creation.create!(
        user: user_uuid,
        parent: parent_uuid,
        child_purposes: [purpose_uuid] * wells_with_matching_samples.count,
        tube_attributes: tube_attributes
      ).children.index_by(&:name)
    end

    def transfer_request_attributes
      index = 0
      request_hashes = []
      # for each sample
      wells_with_matching_samples.each do |sample_uuid, well_filter_hashes|
        puts "*** sample_uuid ***"
        puts sample_uuid

        well_filter_hashes.each do |well_filter_hash|
          well_filter_hash.each do |well, additional_parameters|
            puts "*** well ***"
            puts well
            puts "*** additional_parameters ***"
            puts additional_parameters

            # TODO child tube nil here atm
            request_hashes << request_hash(well, @child_stock_tubes[index], additional_parameters)
          end
        end
        index += 1
      end
      request_hashes
    end

    # returns hash of samples to wells that contain that sample, in the form:
    # sample uuid => [ well filter info ]
    def pools_hash(filtered_wells)
      output = {}
      filtered_wells.each do |well, additional_parameters|
        # TODO: error if well has >1 sample
        next if well.empty?
        # binding.pry

        sample_uuid = well.aliquots.first.sample.uuid
        if output.key? sample_uuid
          output[sample_uuid] << {well => additional_parameters}
        else
          output[sample_uuid] = [{well => additional_parameters}]
        end
      end
      puts "*** pools_hash output ***"
      puts output
      output
    end

    # output the transfer requests that will be sent to Sequencescape
    # to control the creation of aliquots & samples in the new labwares
    def request_hash(source_well, child_tube, additional_parameters)
      # binding.pry
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_tube.receptacle.uuid,
        'merge_equivalent_aliquots' => true
      }.merge(additional_parameters)
    end

    def parent
      @parent ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent_uuid)
    end

    def labware_wells
      parent.wells
    end

    private

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    def wells_with_matching_samples
      @wells_with_matching_samples ||= pools_hash(well_filter.filtered)
    end

    def tube_attributes
      puts "*** wells_with_matching_samples ***"
      puts wells_with_matching_samples
      wells_with_matching_samples.values.map do |sample_well_details|
        # { name: name_for(sample_well_details) }
        puts "*** sample_well_details ***"
        puts sample_well_details
        { name: name_for(sample_well_details) }
      end
    end

    def name_for(sample_well_details)
      names = []
      sample_well_details.each do |well_hash|
        names << well_hash.keys[0].position["name"]
      end
      puts "name_for names = #{names.join(',')}"
      "#{stock_plate_barcode} #{names.join(',')}"
    end

    def stock_plate_barcode
      legacy_barcode = "#{parent.stock_plate.barcode.prefix}#{parent.stock_plate.barcode.number}"
      metadata_stock_barcode || legacy_barcode
    end

    def metadata_stock_barcode
      @metadata_stock_barcode ||= parent_metadata.fetch('stock_barcode', nil)
    end

    def parent_metadata
      if parent.is_a? Limber::Plate
        LabwareMetadata.new(api: api, labware: parent).metadata
      else
        LabwareMetadata.new(api: api, barcode: parent.barcode.machine).metadata
      end || {}
    end
  end
end

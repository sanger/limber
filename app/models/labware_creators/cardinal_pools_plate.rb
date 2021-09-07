# frozen_string_literal: true

# require_dependency 'form'
# require_dependency 'labware_creators'

# 1. Create a new empty LCA PBMC Pools plate

# 2. Get the number of not failed samples in the parent (LCA PBMC) plate

# 3. Look up the pooling config for that number 
# e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool.

# 4. Group samples using group size from above, where random samples are used in the pool

# 5. Add the group of samples (pool) to a well in the new LCA PBMC Pools plate
module LabwareCreators
  class CardinalPoolsPlate < Base 
    include SupportParent::PlateOnly    
    # include LabwareCreators::CustomPage
    
    @@pooling_config = {}

    # self.page = 'cardinal_pools_plate'

    def self.pooling_config
      @@pooling_config
    end

    def self.pooling_config=(config)
      @@pooling_config = config
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

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||=  {"A1": {"dest_locn": "H12"}} # dilutions_calculator.compute_well_transfers(parent)
    end

    private

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    def transfer_material_from_parent!(child_uuid)
      child_plate = Sequencescape::Api::V2::Plate.find_by(uuid: child_uuid)
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    def transfer_request_attributes(child_plate)
      return []
      well_filter.filtered.map do |well, additional_parameters|
        request_hash(well, child_plate, additional_parameters)
      end
    end

    
  end
end
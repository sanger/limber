# frozen_string_literal: true

# require_dependency 'form'
# require_dependency 'labware_creators'

# 1. Create a new empty LCA PBMC Pools plate

# 2. Get the not failed samples in the parent (LCA PBMC) plate

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

    def get_passed_parent_samples
      parent.wells.select { |sample| sample.state == "passed" }
    end

    # { number: 96, pool_1: 12, pool_2: 12, pool_3: 12, pool_4: 12, pool_5: 12, pool_6: 12, pool_7: 12, pool_8: 12 }
    def get_config_for_number_of_passed_samples
      number_of_passed_samples_for_dest = get_passed_parent_samples.count
      @@pooling_config[number_of_passed_samples_for_dest]
    end

    def pool_passed_samples_containing_more_than_one_blood_location
      # all suppliers are the same
      # return if parent.wells.all? { |well| well.supplier == parents.wells.first.supplier }

      # #<Sequencescape::Api::V2::Well:@attributes={"type"=>"wells", "name"=>"DN1S:A4", "position"=>{"name"=>"A4"}, "state"=>"passed", "uuid"=>"2-well-A4", "diluent_volume"=>nil, "pcr_cycles"=>nil, "submit_for_sequencing"=>nil, "sub_pool"=>nil, "coveraga"=>nil, "supplier"=>"blood location 2"}>

      sample_groups_by_supplier = parent.wells.map(&:aliquots).map(&:sample).group_by{ |well| well[:supplier] }
      # {0=>['w1ws1', 'w2ws1'], 1=>['w3ws2', 'w4ws2'], 2=>['w5s3', 'w6s3']}

      # initialise starting pool
      pool_id = 1 #TODO stop at 8 - use [0..7] instead??
      # for each supplier group
      sample_groups_by_supplier.count.times do |i|
        # loop through the samples for that supplier
        # adding each sample to a different pool
        sample_groups_by_supplier[i].each_with_index do |sample, sample_index|
          # check the current pool isnt full
          config = get_config_for_number_of_passed_samples
          max_number_for_pool = config["pool_#{pool_1}"]

          # create the pool_n_samples list if it doesnt already exist
          unless config["pool_#{pool_1}_samples"]
            config["pool_#{pool_1}_samples"] = []
          end

          # adding a sample
          if config["pool_#{pool_1}_samples"].count < max_number_for_pool
            config["pool_#{pool_1}_samples"] << sample
          end

          pool_id ++ # limit at 8 and cycle through again?
        end
      end

      return config
    end

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

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid,
        # 'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||=  {"A1": {"dest_locn": "H12"}} # dilutions_calculator.compute_well_transfers(parent)

      # {
      #   'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '1.0', 'volume' => '20.0' },
      #   'B1' => { 'dest_locn' => 'A2', 'dest_conc' => '2.5', 'volume' => '0.893' },
      #   'C1' => { 'dest_locn' => 'B2', 'dest_conc' => '2.5', 'volume' => '14.286' },
      #   'D1' => { 'dest_locn' => 'C2', 'dest_conc' => '1.8', 'volume' => '20.0' }
      # }
    end

  end
end

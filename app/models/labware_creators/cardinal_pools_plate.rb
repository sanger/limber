# frozen_string_literal: true

#
# require_dependency 'form'
# require_dependency 'labware_creators'

# 1. Create a new empty LCA PBMC Pools plate

# 2. Get the not failed samples in the parent (LCA PBMC) plate

# 3. Look up the pooling config for that number
# e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool.

# 4. Group samples using group size from above, where random samples are used in the pool

# 5. Add the group of samples (pool) to a well in the new LCA PBMC Pools plate
module LabwareCreators
  # This class is used for creating randomicardinal pools into destination plate
  class CardinalPoolsPlate < Base
    include SupportParent::PlateOnly
    # include LabwareCreators::CustomPage

    class << self
      attr_reader :pooling_config
    end

    class << self
      attr_writer :pooling_config
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    def labware_wells
      parent.wells
    end

    # returns
    # a list of passed samples
    def passed_parent_samples
      parent.wells.select { |well| well.state == 'passed' }
    end

    # returns
    # gets all the samples for a plate
    # randomise samples
    # group by supplier
    # {0=>['w1', 'w4'], 1=>['w6', 'w2'], 2=>['w9', 'w23']}
    def samples_grouped_by_supplier
      parent.wells.map(&:aliquots).flatten.map(&:sample).shuffle.group_by { |sample| sample[:supplier] }
    end

    # returns
    # the number of pools required for a given passed samples count
    # this is appended to the config in the Cardinal initialiser
    # e.g. 95,12,12,12,12,12,12,12,11 ==> 8
    # e.g. 53,11,11,11,10,10,,, ==> 5
    def number_of_pools
      self.class.pooling_config[passed_parent_samples.count]
    end

    # returns
    def build_pools
      # all suppliers are the same
      # return if parent.wells.all? { |well| well.supplier == parents.wells.first.supplier }

      pool_id = 1
      pools = []

      # for each suppier group
      samples_grouped_by_supplier.each do |_k, v|
        # loop through the samples for that supplier
        v.each_with_index do |sample, sample_index|
          # adding each sample to a different pool
          pool_id = (sample_index % number_of_pools)
          pools[pool_id] = [] unless pools[pool_id]
          pools[pool_id] << sample
        end
      end
      pools
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

    def transfer_request_attributes(_child_plate)
      []
      # well_filter.filtered.map do |well, additional_parameters|
      #   request_hash(well, child_plate, additional_parameters)
      # end
    end

    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' => child_plate.wells.detect do |child_well|
          child_well.location == transfer_hash[source_well.location]['dest_locn']
        end&.uuid
        # 'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    def transfer_hash
      @transfer_hash ||= { A1: { dest_locn: 'H12' } } # dilutions_calculator.compute_well_transfers(parent)

      # {
      #   'A1' => { 'dest_locn' => 'A1', 'dest_conc' => '1.0', 'volume' => '20.0' },
      #   'B1' => { 'dest_locn' => 'A2', 'dest_conc' => '2.5', 'volume' => '0.893' },
      #   'C1' => { 'dest_locn' => 'B2', 'dest_conc' => '2.5', 'volume' => '14.286' },
      #   'D1' => { 'dest_locn' => 'C2', 'dest_conc' => '1.8', 'volume' => '20.0' }
      # }
    end
  end
end

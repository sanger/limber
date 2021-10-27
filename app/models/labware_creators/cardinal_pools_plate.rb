# frozen_string_literal: true

# require_dependency 'form'
# require_dependency 'labware_creators'

# Algorithm:
# 1. Create a new empty LCA PBMC Pools plate
# 2. Get the passed wells from the parent (LCA PBMC) plate
# 3. For the number of passed wells, get the number of pools from config
# e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool
# 4. Group samples by supplier, to ensure samples with the same supplier are distrubuted across different pools
# 5. Create the group of samples in SS with a different tag depth for each sample, adding the pool to a well
# in the new LCA PBMC Pools plate
module LabwareCreators
  # This class is used for creating Cardinal pools into destination plate
  class CardinalPoolsPlate < Base
    include SupportParent::PlateOnly

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    # parent is using SS v1 API
    # so this method is used to access the plate via SS v2 API
    def source_plate
      @source_plate ||= Sequencescape::Api::V2::Plate.find_by(uuid: parent.uuid)
    end

    # Returns: a list of passed wells passed_parent_wells
    def passed_parent_wells
      source_plate.wells.select { |well| well.state == 'passed' }
    end

    def pools
      @pools ||= build_pools
    end

    # Returns: the number of pools required for a given passed samples count
    # this config is appended in the Cardinal initialiser
    # e.g. 95,12,12,12,12,12,12,12,11 ==> 8
    # e.g. 53,11,11,11,10,10,,, ==> 5
    def number_of_pools
      Rails.application.config.cardinal_pooling_config[passed_parent_wells.count]
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

    # returns: a list of objects, mapping source well to destination well
    # e.g [{'source_asset': 'auuid', 'target_asset': 'anotheruuid'}]
    def transfer_request_attributes(dest_plate)
      passed_parent_wells.map do |source_well|
        request_hash(source_well, dest_plate)
      end
    end

    # Returns: An instance of Sequencescape::Api::V2::Well
    def get_well_for_plate_location(plate, well_location)
      plate.wells.detect do |well|
        well.location == well_location
      end
    end

    def request_hash(source_well, dest_plate)
      source_location = transfer_hash[source_well.location][:dest_locn]
      {
        'source_asset' => source_well.uuid,
        'target_asset' => get_well_for_plate_location(dest_plate, source_location)&.uuid,
        aliquot_attributes: { 'tag_depth' => tag_depth(source_well) }
      }
    end

    def tag_depth(source_well)
      pools.each do |pool|
        return (pool.index(source_well) + 1).to_s if pool.index(source_well)
        # index + 1 incase of 0th index
      end
    end

    # Returns: [A1, B1, ... H1]
    # Used to assign pools to a destination well, e.g. Pool 1 > A1, Pool2 > B1
    def dest_coordinates
      ('A'..'H').to_a.map { |letter| "#{letter}1" }
    end

    # Returns: an object mapping a source well location to the destination well location
    # e.g. { 'A1': { 'dest_locn': 'B1' }, { 'A2': { 'dest_locn': 'A1' }, { 'A3': { 'dest_locn': 'B1' }}
    # {
    #   "A4"=>{:dest_locn=>"A1"},
    #   "A11"=>{:dest_locn=>"A1"},
    #   "G3"=>{:dest_locn=>"A1"},
    #   "C5"=>{:dest_locn=>"A1"},
    # }
    def transfer_hash
      result = {}

      # Build only once, as this is called in a loop
      pools.each_with_index do |pool, index|
        destination_well_location = dest_coordinates[index]
        pool.each do |well|
          source_position = well.location
          result[source_position] = { dest_locn: destination_well_location }
        end
      end
      result
    end

    # Returns a nested list of wells, grouped by pool
    # e.g. pools = [[w1,w4],[w2,w5],[w3,w6]]
    def build_pools
      pools = []
      current_pool = 0
      # wells_grouped_by_supplier = {0=>['w1', 'w4'], 1=>['w6', 'w2'], 2=>['w9', 'w23']}
      wells_grouped_by_supplier.each do |_supplier, wells|
        # Loop through the wells for that supplier
        wells.each do |well|
          # Create pool if it doesnt already exist
          pools[current_pool] = [] unless pools[current_pool]
          # Add well to pool
          pools[current_pool] << well
          # Rotate through the pools
          current_pool = current_pool == number_of_pools - 1 ? 0 : current_pool + 1
        end
      end
      pools
    end

    # Get passed parent wells, randomise, then group by sample supplier
    # e.g. { 0=>['w1', 'w4'], 1=>['w6', 'w2'], 2=>['w9', 'w23'] }
    def wells_grouped_by_supplier
      passed_parent_wells.to_a.shuffle.group_by { |well| well.aliquots.first.sample.sample_manifest.supplier_name }
    end
  end
end

# frozen_string_literal: true

# require_dependency 'form'
# require_dependency 'labware_creators'

# Algorithm:
# 1. Create a new empty LCA PBMC Pools plate
# 2. Get the passed wells from the parent (LCA PBMC) plate
# 3. For the number of passed wells, get the number of pools from config
# e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool
# 4. Group samples by supplier, to ensure samples with the same supplier are distrubuted across different pools
# 5. Create the compound sample in SS - adding the pool to a well in the new LCA PBMC Pools plate
# 6. Associate compound sample with its component samples
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

    # Returns: a list of passed wellspassed_parent_wells
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

      # A "compound" sample should be created for each "pool"
      ###
      # Check how to create groups of requests
      ###
      pools.each_with_index do |pool, index|
        # For each pool, get the destination plate well
        # This assumes pools are ordered?
        destination_well_location = dest_coordinates[index]

        target_well = get_well_for_plate_location(dest_plate, destination_well_location)

        # Create the "compound" sample in SS
        # Check sample is created in the MLWH samples table
        # TODO: Check sample is created in the MLWH samples table
        compound_sample = create_sample(pool, target_well)

        # Update the well with the compound sample
        # This adds the compount sample to the destination plate well,
        # This creates the aliquot on the compound sample
        add_sample_to_well_and_update_aliquot(compound_sample, target_well)

        # For each pool, associate the component samples with the copound sample
        # attach_component_samples_to_compound_sample(compound_sample, destination_well_location, pool)
      end
      #create_submission_for_dest_plate(dest_plate)
    end

    def sample_compound_component_data(samples_and_wells, target_well)
      samples_and_wells.map do |obj|
        { sample_id: obj[:sample].id, asset_id: obj[:well].id, target_asset_id: target_well.id }
      end
    end

    def samples_and_wells_from_pool(pool)
      pool.map do |w|
        { sample: w.aliquots.to_a[0].sample, well: w }
      end
    end

    def create_sample(pool, target_well)
      # TODO: Check compound sample is created in MLWH db with component samples
      Sequencescape::Api::V2::Sample.create(
        name: "CompoundSample_#{target_well.name.tr(':', '_')}",
        sanger_sample_id: "CompoundSample_#{target_well.name.tr(':', '_')}"
      ).tap do |compound_sample|
        # Associate the component samples to the compound sample
        # Inserts a record in SS sample_links table, and MLWH sample_links table
        samples_and_wells = samples_and_wells_from_pool(pool)
        compound_sample.update(component_samples: samples_and_wells.pluck(:sample))
        compound_sample.save

        compound_sample.sample_compound_component_data = sample_compound_component_data(samples_and_wells, target_well)
        compound_sample.save

        api.transfer_request_collection.create!(
          user: user_uuid,
          transfer_requests: samples_and_wells.pluck(:well).map do |well|
            { 
              source_asset: well.uuid, 
              target_asset: target_well.uuid,
              dont_transfer_anything: true
            }
          end
        )  
      end
    end

    # Returns: An instance of Sequencescape::Api::V2::Well
    def get_well_for_plate_location(plate, well_location)
      plate.wells.detect do |well|
        well.location == well_location
      end
    end

    def add_sample_to_well_and_update_aliquot(sample, target_well)
      # This creates a aliquot with default values
      target_well.update(samples: [sample])

      # We then need to update the aliquots study, project and library_type
      # TODO: Move values into config, not hard coded, ENV var?
      aliquot = target_well.aliquots[0]
      aliquot.update(library_type: 'standard', study_id: default_study_id, project_id: default_project_id)
    end

    def default_study_id
      values = source_plate.wells.map { |w| w.aliquots.first.study_id }.uniq
      raise 'There should only be one study in the source plate for pooling' unless (values.count == 1)

      values.first
    end

    def default_project_id
      values = source_plate.wells.map { |w| w.aliquots.first.project_id }.uniq
      raise 'There should only be one project in the source plate for pooling' unless (values.count== 1)

      values.first
    end

    def create_submission_for_dest_plate(dest_plate)
      submission_options_from_config = purpose_config.submission_options
      # if there's more than one appropriate submission, we can't know which one to choose,
      # so don't create one.
      return unless submission_options_from_config.count == 1

      # otherwise, create a submission with params specified in the config
      configured_params = submission_options_from_config.values.first

      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        labware_barcode: dest_plate.barcode,
        request_options: configured_params[:request_options],
        asset_groups: [{ assets: dest_wells_filled_with_a_compound_sample(dest_plate).pluck(:uuid), autodetect_studies_projects: true }],
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      ss.save # TODO: check if true, handle if not
    end

    # Returns: [A1, B1, ... H1]
    # Used to assign pools to a destination well, e.g. Pool 1 > A1, Pool2 > B1
    def dest_coordinates
      ('A'..'H').to_a.map { |letter| "#{letter}1" }
    end

    # "A11"=>{:dest_locn=>"A1"}, "G3"=>{:dest_locn=>"A1"}, "C5"=>{:dest_locn=>"A1"}}
    # Returns ["A1"]
    def dest_coordinates_filled_with_a_compound_sample
      transfer_hash(pools).map { |_k, v| v[:dest_locn] }.uniq
    end

    # Returns a list of wells which contain a compound sample
    def dest_wells_filled_with_a_compound_sample(dest_plate)
      dest_plate.wells.filter { |w| dest_coordinates_filled_with_a_compound_sample.include?(w.location) }
    end

    # Returns: an object mapping a source well location to the destination well location
    # e.g. { 'A1': { 'dest_locn': 'B1' }, { 'A2': { 'dest_locn': 'A1' }, { 'A3': { 'dest_locn': 'B1' }}
    # {
    #   "A4"=>{:dest_locn=>"A1"},
    #   "A11"=>{:dest_locn=>"A1"},
    #   "G3"=>{:dest_locn=>"A1"},
    #   "C5"=>{:dest_locn=>"A1"},
    # }
    def transfer_hash(pools)
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
      passed_parent_wells.to_a.shuffle.group_by { |well| well.aliquots.first.sample.sample_metadata.supplier_name }
    end
  end
end

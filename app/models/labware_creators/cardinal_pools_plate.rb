# frozen_string_literal: true

# require_dependency 'form'
# require_dependency 'labware_creators'

# Algorithm:
# 1. Create a new empty LCA PBMC Pools plate
# 2. Get the passed wells from the parent (LCA PBMC) plate
# 3. For the number of passed wells, get the number of pools from config
# e.g. if there are 96 passed wells on the parent, the samples get split into 8 pools, with 12 samples per pool
# 4. Group samples by supplier, to ensure samples with the same supplier are distrubuted across different pools

# 5. Create a Transfer Requests in SS - adding the pool to a well in the new LCA PBMC Pools plate
module LabwareCreators
  # This class is used for creating randomicardinal pools into destination plate
  class CardinalPoolsPlate < Base
    include SupportParent::PlateOnly

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    # This should only be called from passed_parent_wells
    # As we want to only transfer passed wells to the LCA PBMC plate
    # returns: a list of passed samples
    def passed_parent_wells(source_plate)
      source_plate.wells.select { |well| well.state == 'passed' }
    end

    # returns: the number of pools required for a given passed samples count
    # this config is appended in the Cardinal initialiser
    # e.g. 95,12,12,12,12,12,12,12,11 ==> 8
    # e.g. 53,11,11,11,10,10,,, ==> 5
    def number_of_pools(source_plate)
      Rails.application.config.cardinal_pooling_config[passed_parent_wells(source_plate).count]
    end

    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # barcode: DN9000020C

    # Send the transfer request to SS
    def transfer_material_from_parent!(dest_uuid)
      dest_plate = Sequencescape::Api::V2::Plate.find_by(uuid: dest_uuid)
      source_plate = Sequencescape::Api::V2::Plate.find_by(uuid: parent.uuid)

      # Create pools
      # Ensure this is the only place build_pools is called
      @pools ||= build_pools(source_plate)

      # A "compound" sample should be created for each "pool"
      @pools.each_with_index do |pool, index|
        # pool = [s1,s3,s4]

        # For each pool, get the destination plate well
        # This assumes pools are ordered?
        destination_well_location = dest_coordinates[index]

        # Create the "compound" sample in SS
        # Check sample is created in the MLWH samples table
        compound_sample = create_sample(dest_plate.barcode, destination_well_location, pool)

        # Update the well with the compound sample
        # This adds the compount sample to the destination plate well,
        # This creates the aliquot on the compound sample
        add_sample_to_well_and_update_aliquot(compound_sample, dest_plate, destination_well_location)

        # For each pool, associate the component samples with the copound sample
        # attach_component_samples_to_compound_sample(compound_sample, destination_well_location, pool)
      end

      # Transfer request for each component well
      # However this transfer request wont actually transfer the aliquot
      # From the source well, as instead the destination well
      # Already has the compound sample

      # api.transfer_request_collection.create!(
      #   user: user_uuid,
      #   transfer_requests: transfer_request_attributes(dest_plate)
      # )
      # true

      # For each well (with a compound sample?)
      # Create a request
      # Either via a submission, or manually

      # In SS
      # SubmissionTemplate.find_by(name: "Limber - Cardinal")
      # request_type = RequestType.find(127).plate_purposes
      # PlatePurpose.find_by(name: "LCA PBMC Pools")

      # *** Below needs to be added to SS seed ***
      # RequestType::RequestTypePlatePurpose.create(request_type_id: 127, plate_purpose_id: PlatePurpose.find_by(name: "LCA PBMC Pools").id)

      # template_uuid in config
      create_submission_for_dest_plate(dest_plate)
    end


    def create_sample(barcode, well_location, pool)
      # name is unique
      samples = pool.map{|well| well.aliquots.to_a[0].sample }
      #component_samples_payload = sample_uuids.map{|uuid| {type: 'samples', uuid: uuid} }
      Sequencescape::Api::V2::Sample.create(
        name: "CompoundSample#{barcode}#{well_location}",
        sanger_sample_id: "CompoundSample#{barcode}#{well_location}",
        # studies: [] #[study] Param not allowed??
        #relationships: { component_samples: { data: component_samples_payload } }
      ).tap do |compound_sample|
        compound_sample.update_attributes(component_samples: samples)
      end
    end


    def add_sample_to_well_and_update_aliquot(sample, plate, well_location)
      well = get_well_for_plate_location(plate, well_location)

      # well = get_well_for_plate_location(dest_plate, "C1")

      # This creates a aliquot with default values
      # {receptacle_id: 4435,study_id: nil,project_id: nil,library_id: nil,sample_id: 688}
      # api_post "/api/v2/wells/#{well.id}/relationships/samples", { data: [{ type: 'samples', id: sample.id } }] }
      Sequencescape::Api::V2::Well.find(well.id)[0].update_attributes(samples: [sample])

      # Check the data on the aliquot.
      # Updating the aliquot with study, library etc.
      # Aliquot should have study, project, library_type
      aliquot = Sequencescape::Api::V2::Well.find(well.id)[0].aliquots[0]

      # Update Aliquots study, project and library_type
      # study_id in config
      # project in config
      # library_type in config
      Sequencescape::Api::V2::Aliquot.find(aliquot.id)[0].update_attributes(library_type: "standard", study_id: 1, project_id: 1)
    end

    def create_submission_for_dest_plate(dest_plate)
      # ss = SequencescapeSubmission.new({ template_uuid: "33f69080-2124-11ec-91bc-faffc2566f1d", labware_barcode: dest_plate.barcode })

      submission_options_from_config = purpose_config.submission_options
      # if there's more than one appropriate submission, we can't know which one to choose,
      # so don't create one.
      return unless submission_options_from_config.count == 1

      # otherwise, create a submission with params specified in the config
      configured_params = submission_options_from_config.values.first

      sequencescape_submission_parameters = {
        # template_uuid: "33f69080-2124-11ec-91bc-faffc2566f1d",
        template_name: configured_params[:template_name],
        labware_barcode: dest_plate.barcode,
        request_options: configured_params[:request_options],
        asset_groups: [{ assets: dest_wells_filled_with_a_compound_sample(dest_plate).pluck(:uuid), autodetect_studies_projects: true }],
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      ss.save # TODO: check if true, handle if not

      # Labware.find_by_barcode("DN9000053L").wells[0].samples[0].aliquots[0].update_attributes(
      #   request: Labware.find_by_barcode("DN9000053L").wells[0].samples[0].aliquots[0].receptacle.requests[0]
      # )
    end

    def get_well_for_plate_location(plate, well_location)
      plate.wells.detect do |well|
        well.location == well_location
      end
    end

    def get_receptable_for_well(well)
      Sequencescape::Api::V2::Receptacle.find(well.id)
    end

    # This adds the component sample to the compound sample
    # Inserts a record in SS sample_links table, and MLWH sample_links table
    def attach_component_samples_to_compound_sample(compound_sample, destination_well_location, component_samples)
      component_samples_payload = component_samples.each_with_index.map { |s, _pos| { type: 'samples', id: s.id } }
      # TODO
      # api_post "/api/v2/samples/#{compound_sample.id}/relationships/component_samples", { data: component_samples_payload }
    end

    # returns: a list of objects, mapping source well to destination well
    # e.g [{'source_asset': 'auuid', 'target_asset': 'anotheruuid'}]
    def transfer_request_attributes(dest_plate)
      passed_parent_wells.map do |source_well, additional_parameters|
        request_hash(source_well, dest_plate, additional_parameters)
      end
    end

    def request_hash(source_well, dest_plate, _additional_parameters)
      {
        'source_asset' => source_well.uuid,
        # 'target_asset' => dest_plate.wells.detect do |dest_well|
        #   dest_well.location == transfer_hash[source_well.location][:dest_locn]
        # end&.uuid
        'target_asset' => get_well_for_plate_location(dest_plate, transfer_hash[source_well.location][:dest_locn])&.uuid
      }
    end

    # returns: [A1, B1, ... H1]
    # Used to assign pools to a destination well, e.g. Pool 1 > A1, Pool2 > B1
    def dest_coordinates
      ('A'..'H').to_a.map { |letter| "#{letter}1" }
    end

    # "A11"=>{:dest_locn=>"A1"}, "G3"=>{:dest_locn=>"A1"}, "C5"=>{:dest_locn=>"A1"}}
    # returns ["A1"]
    def dest_coordinates_filled_with_a_compound_sample
      transfer_hash.map do |k,v| p v[:dest_locn] end.uniq
    end

    def dest_wells_filled_with_a_compound_sample(dest_plate)
      dest_plate.wells.filter {|w| dest_coordinates_filled_with_a_compound_sample.include?(w.location)}
    end

    # returns: an object mapping a source well location to the destination well location
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
      # @pools ||= build_pools
      @pools.each_with_index do |pool, index|
        destination_well_location = dest_coordinates[index]
        pool.each do |well|
          source_position = well.location
          result[source_position] = { dest_locn: destination_well_location }
        end
      end
      result
    end

    # e.g. pools = [[s1,s4],[s2,s5],[s3,s6]]
    def build_pools(source_plate)
      pools = []
      current_pool = 0
      # wells_grouped_by_supplier = {0=>['w1', 'w4'], 1=>['w6', 'w2'], 2=>['w9', 'w23']}
      wells_grouped_by_supplier(source_plate).each do |_supplier, wells|
        # Loop through the wells for that supplier
        wells.each do |well|
          # Create pool if it doesnt already exist
          pools[current_pool] = [] unless pools[current_pool]
          # Add well to pool
          pools[current_pool] << well
          # Rotate through the pools
          current_pool = current_pool == number_of_pools(source_plate) - 1 ? 0 : current_pool + 1
        end
      end
      pools
    end

    # Get passed parent wells, randomise, then group by sample supplier
    # e.g. { 0=>['w1', 'w4'], 1=>['w6', 'w2'], 2=>['w9', 'w23'] }
    def wells_grouped_by_supplier(source_plate)
      passed_parent_wells(source_plate).to_a.shuffle.group_by { |well| well.samples[0].sanger_sample_id }
    end
  end
end

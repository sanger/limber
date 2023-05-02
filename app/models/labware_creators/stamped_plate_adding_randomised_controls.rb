# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # Stamps the majority of samples from the parent plate straight into the child
  # plate (A1 to A1, B1 to B1 etc.). Also creates and adds a number of randomised
  # control samples according to configuration from the plate purpose.
  class StampedPlateAddingRandomisedControls < StampedPlate
    PARENT_INCLUDES = 'wells.aliquots,wells.aliquots.samples,wells.aliquots.samples.sample_metadata'

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_INCLUDES, uuid: parent_uuid)
    end

    # fetch list of controls to add from the child purpose configuration
    def list_of_controls
      purpose_config.fetch(:controls)
    end

    # fetch list of rules from the child purpose configuration
    def list_of_rules
      purpose_config.fetch(:control_location_rules)
    end

    # fetch study name from the child purpose configuration
    def control_study_name
      @control_study_name ||= purpose_config.fetch(:control_study_name)
    end

    def generate_control_well_locations
      control_locations = []
      rules_obeyed = false
      while (!rules_obeyed) do
        puts "DEBUG: making locations for #{list_of_controls.count} controls"
        list_of_controls.count.times do |control_index|
          puts "DEBUG: control index = #{control_index}"
          # sample a random parent well and fetch its location
          location = parent.wells.sample.position['name']
          puts "DEBUG: control location selected = #{location}"
          control_locations.push(location)
        end
        # check control locations selected pass rules
        puts "DEBUG: control_locations before rules = #{control_locations}"
        rules_obeyed = validate_control_rules(control_locations)
        puts "DEBUG: rules_obeyed = #{rules_obeyed}"
      end
      control_locations
    end

    private

    def create_plate_with_standard_transfer!
      plate_creation = create_plate_from_parent!
      # create the empty child plate, including empty wells
      @child = plate_creation.child
      # re-fetch the child plate in v2 api so we have access to the v2 wells
      @child_plate_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)
      # generate and allocate control samples to randomised child plate wells
      @control_well_locations = generate_control_well_locations
      puts "DEBUG: control_well_locations after generation = #{@control_well_locations}"
      create_control_samples_in_child_plate
      # transfer samples from parent where wells were not overriden with controls
      transfer_material_from_parent!
      yield(@child) if block_given?
      after_transfer!
      true
    end

    def validate_control_rules(control_locations)
      # check for duplicates
      return false if control_locations.uniq.length != control_locations.length
      # check array obeys rules from config
      list_of_rules.each do |rule|
        if rule.type == 'not'
          return false if control_locations == rule.value
        end
      end
      true
    end

    def create_control_samples_in_child_plate
      list_of_controls.each_with_index do |control, index|
        well_location = @control_well_locations[index]
        child_well = get_well_for_child_plate_location(well_location)
        create_control_in_child_well(control, child_well)
      end
    end

    def get_well_for_child_plate_location(well_location)
      @child_plate_v2.wells.detect { |well| well.location == well_location }
    end

    def parent_wells_with_aliquots
      parent
      .wells
      .each_with_object([]) do |well, wells_with_aliquots|
        wells_with_aliquots << well unless well.aliquots.blank? || well.aliquots.first.sample.blank?
      end
    end

    def control_sample_description
      parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.sample_description
    end

    def control_cohort
      parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.cohort
    end

    def transfer_material_from_parent!
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes.compact
      )
    end

    def transfer_request_attributes
      well_filter.filtered.map do |well, additional_parameters|
        next if @control_well_locations.include?(well.position['name'])
        request_hash(well, @child_plate_v2, additional_parameters)
      end
    end

    def create_control_in_child_well(control, child_well)
      # TODO: how to create samples given not an option in v1
      sample_name = "#{control.name_prefix}#{control_sample_description}_#{child_well.position['name']}"
      puts "DEBUG: create control sample_name = #{sample_name}"
      puts "DEBUG: control_cohort = #{control_cohort}"
      puts "DEBUG: control study =#{control_study_name}"
      puts "DEBUG: control.type =#{control.control_type}"


      # TODO use v2
      # create sample (with metadata), create aliquot, set aliquot in well

      # Sequencescape::Api::V2::Sample.new(name: 'test001').update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first])
      # TODO: returns success true or false, how fetch the sample itself?
      # sample = Sequencescape::Api::V2::Sample.find(name: sample_name)

      # Sequencescape::Api::V2::Sample
      #   .new(
      #     name: sample_name,
      #     supplier_name: sample_name,
      #     control: true,
      #     control_type: control.control_type,
      #     cohort: control_cohort
      #   )
      #   .update(
      #     studies: [
      #       Sequencescape::Api::V2::Study
      #         .find_by(name: control_study_name)
      #         .first
      #     ]
      #   )

      # Sequencescape::Api::V2::Sample.new(name: 'test_001', supplier_sample_name: 'test_001', control: true, control_type: 'positive', cohort: 'mycohort').update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first])

      # Sequencescape::Api::V2::Sample.new(name: 'test_008', supplier_name: 'test_008_sn').update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first])

      # Sequencescape::Api::V2::Sample.new(name: 'test007', sample_metadata: [Sequencescape::Api::V2::SampleMetadata.new(supplier_name: 'test007_sn')]).update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first])

      # Sequencescape::Api::V2::Sample.new(name: 'test008').update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first], sample_metadata: [Sequencescape::Api::V2::SampleMetadata.new(supplier_name: 'test008_sn')])

      # Sequencescape::Api::V2::Sample.new(name: 'test008').update(studies: [Sequencescape::Api::V2::Study.find(name: 'UAT Study').first]).update(sample_metadata: [Sequencescape::Api::V2::SampleMetadata.new(supplier_name: 'test008_sn')])

      # TODO: is study here the name or id?
      # child_well.aliquots.create!(sample: sample, study: control_study_name)
    end
  end
end

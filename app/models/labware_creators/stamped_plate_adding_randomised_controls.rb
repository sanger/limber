# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # Stamps the majority of samples from the parent plate straight into the child
  # plate (A1 to A1, B1 to B1 etc.). Also creates and adds a number of randomised
  # control samples according to configuration from the plate purpose.
  class StampedPlateAddingRandomisedControls < StampedPlate # rubocop:todo Metrics/ClassLength
    PARENT_PLATE_INCLUDES =
      'wells.requests_as_source,wells.requests_as_source.request_type,' \
        'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    # fetch list of controls to add from the child purpose configuration
    def list_of_controls
      purpose_config.fetch(:controls)
    end

    # fetch list of rules from the child purpose configuration
    def list_of_rules
      purpose_config.fetch(:control_location_rules)
    end

    # fetch the project name to use for the control sample from the purpose configuration
    def control_project_name
      @control_project_name ||= purpose_config.fetch(:control_project_name)
    end

    # fetch the study name to use for the control sample from the purpose configuration
    def control_study_name
      @control_study_name ||= purpose_config.fetch(:control_study_name)
    end

    # generate randomised well locations for each control
    def generate_control_well_locations
      control_locations = []
      rules_obeyed = false
      until rules_obeyed
        list_of_controls.count.times do |_control_index|
          # sample a random parent well and fetch its location (child not created yet)
          location = parent.wells.sample.position['name']
          control_locations.push(location)
        end

        # check control locations selected pass rules, otherwise we retry
        rules_obeyed = validate_control_rules(control_locations)
      end
      control_locations
    end

    def control_well_locations
      @control_well_locations ||= generate_control_well_locations
    end

    def labware_wells
      parent.wells.filter_map { |well| well unless control_well_locations.include?(well.position['name']) }
    end

    private

    def create_plate_with_standard_transfer!
      plate_creation = create_plate_from_parent!

      # create the empty child plate, including empty wells
      @child = plate_creation.child

      # re-fetch the child plate in v2 api so we have access to the v2 wells
      @child_plate_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      # create and add the control samples to the child plate in the chosen locations
      create_control_samples_in_child_plate

      # stamp all samples from parent where wells were not overriden with controls
      transfer_material_from_parent!
      yield(@child) if block_given?
      after_transfer!
      true
    end

    # check the selected well locations meet rules specified in purpose configuration
    def validate_control_rules(control_locations)
      # first check for duplicates, in case the sampling chose the same well more than once
      return false if control_locations.uniq.length != control_locations.length

      # check the chosen locations against the rules (will add more options as required)
      list_of_rules.each do |rule|
        # locations must not match (order important)
        return false if rule.type == 'not' && (control_locations == rule.value)
      end
      true
    end

    # create the control samples, place them in the chosen well locations in the child
    # plate, then cancel the requests of any displaced parent wells
    def create_control_samples_in_child_plate
      list_of_controls.each_with_index do |control, index|
        well_location = control_well_locations[index]

        # create the control in the chosen well location in the child plate
        child_well_v2 = well_for_plate_location(@child_plate_v2, well_location)
        create_control_in_child_well(control, child_well_v2, well_location)

        # cancel the parent well request for a sample displaced by the control (if any)
        parent_well_v2 = well_for_plate_location(parent, well_location)
        close_request_in_parent_well(parent_well_v2)

        # TODO: do we need to update the child well state to passed?
      end
    end

    def well_for_plate_location(plate_v2, well_location)
      plate_v2.wells.detect { |well| well.location == well_location }
    end

    def parent_wells_with_aliquots
      parent
        .wells
        .each_with_object([]) do |well, wells_with_aliquots|
          wells_with_aliquots << well unless well.aliquots.blank? || well.aliquots.first.sample.blank?
        end
    end

    # used to fetch the sample description from a parent well, for use in creating the control sample name
    # we are assuming this contains a generic value shared by all samples in the parent plate
    def control_desc
      @control_desc ||= parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.sample_description
    end

    # used to fetch the sample cohort from a parent well, for use in writing to the control sample metadata
    # we are assuming this contains a generic value shared by all samples in the parent plate
    def control_cohort
      @control_cohort ||= parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.cohort
    end

    # fetch the api v2 study object for the control study name from the purpose config
    def control_study_v2
      @control_study_v2 ||= Sequencescape::Api::V2::Study.find(name: control_study_name).first
    end

    # fetch the api v2 project object for the control project name from the purpose config
    def control_project_v2
      @control_project_v2 ||= Sequencescape::Api::V2::Project.find(name: control_project_name).first
    end

    # this transfer collection stamps all the samples from the parent into the child plate,
    # except for those being displaced by controls (uses labware_wells method via well_filter)
    def transfer_material_from_parent!
      api.transfer_request_collection.create!(user: user_uuid, transfer_requests: transfer_request_attributes)
    end

    def transfer_request_attributes
      well_filter.filtered.map do |well, additional_parameters|
        request_hash(well, @child_plate_v2, additional_parameters)
      end
    end

    # create the control sample, setting the sample name and metadata, then create
    # an aliquot containing the control and link it to the selected child well
    def create_control_in_child_well(control, child_well_v2, well_location)
      # check the well should be empty
      unless child_well_v2.aliquots.length.zero?
        errors.add(:base, "Expecting child plate well to be empty at location #{well_location}")
      end

      control_v2 = create_control_sample(control, well_location)

      binding.pry
      update_control_sample_metadata(control_v2, well_location)

      create_aliquot_in_child_well(control_v2, child_well_v2, well_location)
    end

    # create the control sample and metadata NB. sample_name cannot contain spaces!!
    def create_control_sample(control, well_location)
      sample_name = "#{control.name_prefix}#{control_desc}_#{well_location}"
      control_v2 =
        Sequencescape::Api::V2::Sample.new(
          name: sample_name,
          sanger_sample_id: sample_name,
          control: true,
          control_type: control.control_type
        )
      control_v2.relationships.studies = [control_study_v2]
      return control_v2 if control_v2.save

      errors.add(:base, "New control (type #{control.control_type}) did not save for location #{well_location}")
    end

    def update_control_sample_metadata(control_v2, well_location)
      return if control_v2.sample_metadata.update(cohort: control_cohort, sample_description: control_desc)

      errors.add(:base, "Could not update description on control for location #{well_location}")
    end

    # create aliquot in child well to hold the control sample
    def create_aliquot_in_child_well(control_v2, child_well_v2, well_location) # rubocop:todo Metrics/AbcSize
      control_aliquot_v2 = Sequencescape::Api::V2::Aliquot.new

      # set relationships on the new aliquot
      control_aliquot_v2.relationships.sample = control_v2
      control_aliquot_v2.relationships.study = control_study_v2
      control_aliquot_v2.relationships.project = control_project_v2
      control_aliquot_v2.relationships.receptacle = child_well_v2

      # Seems to require setting this attribute on the relationship otherwise we get a TypeMismatch error
      control_aliquot_v2.relationships.attributes['receptacle']['data']['type'] = 'receptacles'

      return if control_aliquot_v2.save

      errors.add(:base, "Could not create aliquot for location #{well_location}")
    end

    # filter on requests matching expected request type
    def suitable_request_for_well(parent_well_v2)
      reqs =
        parent_well_v2.requests_as_source.filter do |request|
          request.request_type.key == purpose_config.fetch(:work_completion_request_type) && request.state == 'pending'
        end
      req = reqs&.sort_by(&:id)&.last
      if req.blank?
        errors.add(:base, "Expected to find suitable request in the parent plate for location #{well_location}")
      end
      req
    end

    # find and close request of type specified by config in the parent well
    # for a well location replaced by a control in the child plate
    def close_request_in_parent_well(parent_well_v2)
      return if parent_well_v2.requests_as_source.blank?

      req = suitable_request_for_well(parent_well_v2)
      return if req.blank?

      # cancel the request
      return if req.update(state: 'cancelled')

      errors.add(:base, "Could not cancel request for well location #{well_location}")
    end
  end
end

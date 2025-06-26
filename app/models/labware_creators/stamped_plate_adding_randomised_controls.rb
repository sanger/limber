# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators'

module LabwareCreators
  # Stamps the majority of samples from the parent plate straight into the child
  # plate (A1 to A1, B1 to B1 etc.). Also creates and adds a number of randomised
  # control samples according to configuration from the plate purpose.
  # NB. This was specifically made for adding 2 controls in Bioscan Lysate plates, with
  # specific sample metdata, and is fairly specific for that purpose.
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
      max_retries = 5
      retries_count = 0

      until retries_count >= max_retries
        # use purpose config settings to create control locations
        control_locations = generate_control_locations_from_purpose_config

        # check control locations selected pass rules, otherwise we retry with new locations
        return control_locations if validate_control_rules(control_locations)

        retries_count += 1
      end

      raise StandardError, "Control well location randomisation failed to pass rules after #{max_retries} attempts"
    end

    def control_well_locations
      @control_well_locations ||= generate_control_well_locations
    end

    def labware_wells
      parent.wells.reject { |well| control_well_locations.include?(well.position['name']) }
    end

    # check the selected well locations meet rules specified in purpose configuration
    def validate_control_rules(control_locations)
      # first check for duplicates, in case the sampling chose the same well more than once
      return false if control_locations.uniq.length != control_locations.length

      # check the chosen locations against the purpose config rules (will add more options as required)
      check_control_rules_from_config(control_locations)
    end

    private

    def generate_control_locations_from_purpose_config
      control_locations = []
      list_of_controls.count.times do |control_index|
        control = list_of_controls[control_index]
        if control.fixed_location?
          # use the location specified in the purpose config for this control
          control_locations.push(control.fixed_location)
        else
          # sample a random parent well and fetch its location (child not created yet)
          control_locations.push(parent.wells.sample.position['name'])
        end
      end
      control_locations
    end

    def check_control_rules_from_config(control_locations)
      list_of_rules.each do |rule|
        case rule.type
        when 'not'
          # locations must not match this combination of wells (order is important)
          return false if control_locations == rule.value
        when 'well_exclusions'
          # locations must not be in this list well locations (exclusions)
          return false if control_locations.any? { |location| rule.value.include?(location) }
        else
          # check for unrecognised rule type
          raise StandardError, "Unrecognised control locations rule type from purpose config #{rule.type}"
        end
      end
      true
    end

    def create_plate_with_standard_transfer!
      plate_creation = create_plate_from_parent!

      # create the empty child plate, including empty wells
      @child = plate_creation.child

      # re-fetch the child plate in v2 api so we have access to the v2 wells
      @child_plate_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      # create and add the control samples to the child plate in the chosen locations
      create_control_samples_in_child_plate

      # close off requests on displaced samples
      cancel_requests_for_samples_displaced_by_controls

      # stamp all samples from parent where wells were not overriden with controls
      transfer_material_from_parent!
      yield(@child) if block_given?
      after_transfer!

      # call stock register if there is register_stock_plate flag
      register_stock_for_plate if @child_plate_v2.register_stock_plate?

      true
    end

    def register_stock_for_plate
      # call Sequencescape::Api::V2::Plate register_stock_for_plate method
      if @child_plate_v2.register_stock_for_plate
        Rails.logger.info("Stock registration successful for plate #{@child.uuid}")
      else
        Rails.logger.error(
          "Stock registration failed for plate #{@child.uuid}: #{@child_plate_v2.errors.full_messages.join(', ')}"
        )
      end
    rescue StandardError => e
      Rails.logger.error("Stock registration error for plate #{@child.uuid}: #{e.message}")
    end

    # create the control samples in the chosen well locations in the child plate
    def create_control_samples_in_child_plate
      list_of_controls.each_with_index do |control, index|
        well_location = control_well_locations[index]

        child_well_v2 = well_for_plate_location(@child_plate_v2, well_location)
        create_control_in_child_well(control, child_well_v2, well_location)
      end
    end

    # cancel the requests of any displaced parent well samples
    def cancel_requests_for_samples_displaced_by_controls
      list_of_controls.each_with_index do |_control, index|
        well_location = control_well_locations[index]

        parent_well_v2 = well_for_plate_location(parent, well_location)
        cancel_request_in_parent_well(parent_well_v2)
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
    # (which MUST be unique)
    # we are assuming this contains a value shared by all samples in the parent plate e.g. this will be the
    # Specimen plate barcode for Bioscan
    def control_desc
      @control_desc ||= generate_control_sample_desc
    end

    def generate_control_sample_desc
      parent_sample_desc = parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.sample_description
      parent_sample_desc = parent.human_barcode if parent_sample_desc.blank?
      parent_sample_desc
    end

    # used to fetch the sample cohort from a parent well, for use in writing to the control sample metadata
    # we are assuming this contains a generic value shared by all samples in the parent plate
    def control_cohort
      @control_cohort ||= generate_control_cohort
    end

    def generate_control_cohort
      parent_cohort = parent_wells_with_aliquots.first.aliquots.first.sample.sample_metadata.cohort
      if parent_cohort.blank?
        # TODO: R&D checking if ok for this field to remain blank i.e. can be blank in mBrave file
        parent_cohort = parent.human_barcode
      end
      parent_cohort
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
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
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
      unless child_well_v2.aliquots.empty?
        raise StandardError, "Expecting child plate well to be empty at location #{well_location}"
      end

      control_v2 = create_control_sample(control, well_location)

      update_control_sample_metadata(control_v2, well_location)

      create_aliquot_in_child_well(control_v2, child_well_v2, well_location)
    end

    # create the name for the control
    # NB. using child labware barcode in the name to ensure uniqueness when lab does repeat runs
    def create_control_sample_name(control, well_location)
      "#{control.name_prefix}#{child.labware_barcode.human}_#{well_location}"
    end

    # create the control sample and metadata NB. sample_name cannot contain spaces!!
    def create_control_sample(control, well_location)
      sample_name = create_control_sample_name(control, well_location)

      # sample name must not contain spaces, if it does replace with underscores
      sample_name.parameterize.underscore
      control_v2 =
        Sequencescape::Api::V2::Sample.new(
          name: sample_name,
          sanger_sample_id: sample_name,
          control: true,
          control_type: control.control_type
        )
      control_v2.relationships.studies = [control_study_v2]

      return control_v2 if control_v2.save

      raise StandardError, "New control (type #{control.control_type}) did not save for location #{well_location}"
    end

    def update_control_sample_metadata(control_v2, well_location)
      if control_v2.sample_metadata.update(
        supplier_name: control_v2.name,
        cohort: control_cohort,
        sample_description: control_desc
      )
        return
      end

      raise StandardError, "Could not update description on control for location #{well_location}"
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

      raise StandardError, "Could not create aliquot for location #{well_location}"
    end

    # filter on requests matching expected request type
    def suitable_request_for_well(parent_well_v2)
      reqs =
        parent_well_v2.requests_as_source.filter do |request|
          request.request_type.key == purpose_config.fetch(:work_completion_request_type) && request.state == 'pending'
        end

      reqs&.max_by(&:id)
    end

    # find and close request of type specified by config in the parent well
    # for a well location replaced by a control in the child plate
    def cancel_request_in_parent_well(parent_well_v2)
      return if parent_well_v2.requests_as_source.blank?

      req = suitable_request_for_well(parent_well_v2)
      return if req.blank?

      # cancel the request
      return if req.update(state: 'cancelled')

      raise StandardError, "Could not cancel request for well location #{well_location}"
    end
  end
end

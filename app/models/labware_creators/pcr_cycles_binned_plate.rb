# frozen_string_literal: true

module LabwareCreators
  # Handles the generation of a plate with wells binned according to the number of
  # PCR cycles that has been determined by the customer.
  # Uploads a file supplied by the customer that has a row per each well and
  # includes Sample Volume, Diluent Volume, PCR Cycles, Sub-Pool, Coverage and Hyb Panel columns.
  # Uses the PCR Cycles column to determine the binning arrangement of the wells,
  # and the Sample Volume and Diluent Volume columns in the well transfers.
  # Rows with a Sample Volume of zero mean the customer does not want that sample
  # to go forward at this time, and it should not be transferred into the dilution plate.
  # Sub-Pool, Coverage and Hyb Panel need to be stored for a later step downstream in the
  # pipeline, at the point where custom pooling is performed.
  # Wells in the bins are applied to the destination by column order.
  # If there is enough space on the destination plate each new bin will start in a new
  # column. Otherwise bins will run consecutively without gaps.
  #
  #
  # Source Plate                  Dest Plate
  # +--+--+--~                    +--+--+--~
  # |A1| pcr_cycles = 12 (bin 2)  |B1|A1|C1|
  # +--+--+--~                    +--+--+--~
  # |B1| pcr_cycles = 15 (bin 1)  |D1|E1|  |
  # +--+--+--~  +                 +--+--+--~
  # |C1| pcr_cycles = 10 (bin 3)  |  |G1|  |
  # +--+--+--~                    +--+--+--~
  # |D1| pcr_cycles = 15 (bin 1)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |E1| pcr_cycles = 12 (bin 2)  |  |  |  |
  # +--+--+--~                    +--+--+--~
  # |G1| pcr_cycles = 12 (bin 2)  |  |  |  |
  class PcrCyclesBinnedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly
    self.default_transfer_template_name = 'Custom pooling'

    MISSING_WELL_DETAIL = 'is missing a row for well %s, all wells with content must have a row in the uploaded file.'
    PENDING_WELL = 'contains at least one pending well %s, the plate and all wells in it '\
      'should be passed before creating the child plate.'
    NO_WELLS_TO_TRANSFER = 'has no well rows suitable for transfer (check sample volumes)'

    self.page = 'pcr_cycles_binned_plate'
    self.attributes += [:file]

    attr_accessor :file

    # delegate method to return well values to csv file handler class
    delegate :well_details, :skipped_wells, to: :csv_file

    validates :file, presence: true
    validates_nested :csv_file, if: :file
    validate :wells_have_required_information?
    validate :some_wells_are_being_transferred?

    PARENT_PLATE_INCLUDES = 'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,'\
      'wells.aliquots.request.request_type,wells.aliquots.study'
    CHILD_PLATE_INCLUDES = 'wells.aliquots'
    REQUEST_METADATA_FIELDS = %w[diluent_volume pcr_cycles submit_for_sequencing sub_pool coverage bait_library_id].freeze

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    def parent_v1
      @parent_v1 ||= api.plate.find(parent_uuid)
    end

    #
    # csv file configuration from the plate purpose.
    #
    def csv_file_upload_config
      @csv_file_upload_config ||= purpose_config.fetch(:csv_file_upload)
    end

    #
    # submission configuration from the plate purpose.
    #
    def submission_options
      @submission_options ||= purpose_config.fetch(:submission_options)
    end

    def save
      # NB. need the && true!!
      super && upload_file && true
    end

    #
    # Called as part of the 'super' call in the 'save' method
    #
    def after_transfer!
      puts "DEBUG: in after_transfer!"
      puts "DEBUG: in after_transfer!: well_filter.filtered = #{well_filter.filtered}"
      # The uuid for the correct request for the submission is in the well_filter filtered as 'outer_request'
      well_filter.filtered.each do |well, additional_parameters|
        puts "DEBUG: in after_transfer!: well = #{well.position['name']}"
        well_detail = well_details[well.position['name']]
        puts "DEBUG: in after_transfer!: well_detail = #{well_detail}"

        # The uuid for the correct request for the submission is in the well_filter filtered as 'outer_request'
        filtered_request_uuid = additional_parameters['outer_request']
        puts "DEBUG: in after_transfer!: filtered_request_uuid = #{filtered_request_uuid}"

        # fetch the Request and update it
        filtered_request = Sequencescape::Api::V2::Request.where(uuid: filtered_request_uuid).first
        puts "DEBUG: in after_transfer!: filtered_request retrieved, try to update"
        update_request_with_metadata(filtered_request, well_detail, REQUEST_METADATA_FIELDS)
      end
    end

    #
    # Update metadata on a request to be accessible on descendants
    #
    def update_request_with_metadata(filtered_request, metadata, fields_to_update)
      puts "DEBUG: update_request_with_metadata"
      options = fields_to_update.index_with { |field| metadata[field] }

      # TODO: need to use API v1 to update request
      # @robot = Robots.find(id: params[:id], api: api, user_uuid: current_user_uuid)

      puts "DEBUG: update_request_with_metadata: options = #{options}"
      filtered_request.update(options)
    end

    #
    # The dilutions calculator works out how the samples will we rearranged when
    # transferred into the child plate
    #
    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(well_details)
    end

    def labware_wells
      parent.wells
    end

    private

    #
    # Well filter handles the selection of wells for transfer based on submission id
    #
    def well_filter
      @well_filter ||= WellFilterBySubmission.new(creator: self, submission_id: @submission.id)
    end

    #
    # Validation to check that at least some wells should be transferred
    # to catch situation where customer file has no valid rows (e.g. all zero sample volume)
    #
    def some_wells_are_being_transferred?
      return true unless well_details.size.zero?

      errors.add(:csv_file, format(NO_WELLS_TO_TRANSFER))
      false
    end

    def check_for_well_missing_detail(well)
      return if well_details.include? well.location
      errors.add(:csv_file, format(MISSING_WELL_DETAIL, well.location))
    end

    def check_for_well_pending(well)
      return unless well.pending?
      errors.add(:csv_file, format(PENDING_WELL, well.location))
    end

    #
    # Validation to check wells have the required information and are in the right state
    #
    def wells_have_required_information?
      labware_wells.each do |well|
        # skip validation on wells empty or chosen not to go forward (those where user has set zero sample vol)
        next if well.aliquots.empty? || skipped_wells.include?(well.location)

        check_for_well_missing_detail(well)
        check_for_well_pending(well)
      end
    end

    #
    # Creates and builds the submission, creates the child plate labware and
    # transfers samples from the parent plate to the child plate
    #
    def create_labware!
      create_and_build_submission
      return if errors.size.positive?

      plate_creation = create_plate_from_parent!
      @child = plate_creation.child

      child_v2 = Sequencescape::Api::V2.plate_with_wells(@child.uuid)

      transfer_material_from_parent!(child_v2)

      yield(@child) if block_given?
      after_transfer!
      true
    end

    #
    # Creates and builds the submission for the dilution and cleanup step
    #
    def create_and_build_submission
      submission_created = create_submission_from_parent_plate
      unless submission_created
        errors.add(:base, 'Failed to create submission')
        return
      end

      errors.add(:base, 'Submission failed to build in a reasonable timeframe') unless submission_built?

      # submission_built? may not mean a successful submission, just that job completed, so check state and message
      errors.add(:base, 'Submission has failed') if @submission.state == 'failed'
      errors.add(:base, @submission.message) if @submission.message.present?
    end

    #
    # Checks that the submission has been built, waiting if not
    #
    def submission_built?
      counter = 1
      while counter <= 6
        @submission = Sequencescape::Api::V2::Submission.where(uuid: @submission_uuid).first
        return true unless @submission.building_in_progress?

        sleep(5)
        counter += 1
      end
      false
    end

    #
    # Fetches the dilution and cleanup submission options from the purpose
    # configuration and calls the method to create the submission
    #
    def create_submission_from_parent_plate
      # there should only be one submission option
      if submission_options.count > 1
        errors.add(:base, 'Expected only one submission')
        return
      end

      # create a submission with params specified in the config
      configured_params = submission_options.values.first

      create_submission(configured_params)
    end

    #
    # Fetch the parent well uuids for those wells being transferred
    #
    def parent_asset_uuids
      labware_wells.filter_map do |well|
        well.uuid unless well.empty? || skipped_wells.include?(well.position['name'])
      end
    end

    #
    # Creates the dilution and cleanup submission
    #
    def create_submission(configured_params)
      sequencescape_submission_parameters = {
        # TODO: this is one order currently
        template_name: configured_params[:template_name],
        # TODO: create hash of orders
        request_options: configured_params[:request_options],
        asset_groups: [{ assets: parent_asset_uuids, autodetect_studies_projects: true }],
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      submission_created = ss.save

      if submission_created
        puts "DEBUG: submission_created: submission uuid = #{ss.submission_uuid}"
        @submission_uuid = ss.submission_uuid
        return true
      end

      errors.add(:base, ss.errors.full_messages)
      false
    end

    #
    # Upload the csv file onto the plate via api v1
    #
    def upload_file
      parent_v1.qc_files.create_from_file!(file, 'pcr_cycles_binned_plate_customer_file.csv')
    end

    #
    # Create class that will parse and validate the uploaded customer csv file
    #
    def csv_file
      @csv_file ||= CsvFile.new(file, csv_file_upload_config, parent.human_barcode)
    end

    #
    # Call the api to create the transfer request collection
    #
    def transfer_material_from_parent!(child_plate)
      puts "DEBUG: transfer_request_attributes = #{transfer_request_attributes(child_plate)}"
      api.transfer_request_collection.create!(
        user: user_uuid,
        transfer_requests: transfer_request_attributes(child_plate)
      )
    end

    #
    # Generates the transfer request attributes
    # e.g [
    #   {
    #     'source_asset': 'auuid',
    #     'target_asset': 'anotheruuid',
    #     'volume': '5.2',
    #     'outer_request': "arequestuuid"
    #   },
    #   { etc. }
    # ]
    #
    def transfer_request_attributes(child_plate)
      # TODO: refetch the parent wells so have submitted requests information
      @parent = Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)

      well_filter.filtered.filter_map do |well, additional_parameters|
        request_hash(well, child_plate, additional_parameters)
      end
    end

    #
    # Generates a request hash for a specific well
    # e.g {
    #   'source_asset': 'auuid',
    #   'target_asset': 'anotheruuid',
    #   'volume': '5.2'
    # }
    #
    def request_hash(source_well, child_plate, additional_parameters)
      {
        'source_asset' => source_well.uuid,
        'target_asset' =>
          child_plate
            .wells
            .detect { |child_well| child_well.location == transfer_hash[source_well.location]['dest_locn'] }
            &.uuid,
        'volume' => transfer_hash[source_well.location]['volume'].to_s
      }.merge(additional_parameters)
    end

    #
    # Uses the calculator to generate the hash of transfers to be performed on the parent plate
    # e.g.
    # {
    #   'A1' => {
    #     'dest_locn' => 'A1',
    #     'volume' => '5.0'
    #   },
    #   'B1' => {
    #     'dest_locn' => 'B1',
    #     'volume' => '5.0'
    #   },
    #   etc.
    # }
    #
    def transfer_hash
      @transfer_hash ||= dilutions_calculator.compute_well_transfers(parent)
    end
  end
end

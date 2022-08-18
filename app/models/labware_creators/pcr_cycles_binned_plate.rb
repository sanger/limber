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
  # rubocop:disable Metrics/ClassLength
  class PcrCyclesBinnedPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly
    self.default_transfer_template_name = 'Custom pooling'

    MISSING_WELL_DETAIL = 'is missing a row for well %s, all wells with content must have a row in the uploaded file.'
    PENDING_WELL =
      'contains at least one pending well %s, the plate and all wells in it ' \
        'should be passed before creating the child plate.'
    NO_WELLS_TO_TRANSFER = 'has no well rows suitable for transfer (check sample volumes)'

    self.page = 'pcr_cycles_binned_plate'
    self.attributes += [:file]

    attr_accessor :file

    delegate :request_metadata_details, :skipped_wells, to: :csv_file

    validates :file, presence: true
    validates_nested :csv_file, if: :file
    validate :wells_have_required_information?
    validate :some_wells_are_being_transferred?

    PARENT_PLATE_INCLUDES =
      'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'
    CHILD_PLATE_INCLUDES = 'wells.aliquots'
    REQUEST_METADATA_FIELDS = %w[
      input_amount_desired
      diluent_volume
      pcr_cycles
      submit_for_sequencing
      sub_pool
      coverage
      bait_library
    ].freeze

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
    # The dilutions calculator works out how the samples will be rearranged when
    # transferred into the child plate
    #
    def dilutions_calculator
      @dilutions_calculator ||= Utility::PcrCyclesBinningCalculator.new(request_metadata_details)
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
      return true unless request_metadata_details.size.zero?

      errors.add(:csv_file, format(NO_WELLS_TO_TRANSFER))
      false
    end

    def check_for_well_missing_detail(well)
      return if request_metadata_details.include? well.location
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
      # check if async submission job has been created ok
      unless create_submission_from_parent_plate
        errors.add(:base, 'Failed to create submission')
        return
      end

      # now check if the async job completed ok
      unless submission_built?
        errors.add(:base, 'Submission failed to build in a reasonable timeframe')
        return
      end

      # Need to also check the state of the submission, as the job can complete ok but the submission fail
      return unless @submission.state == 'failed'

      errors.add(:base, "Submission has failed, error message: #{@submission.message}")
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

      # returns boolean
      create_submission(configured_params)
    end

    #
    # Filtered list of wells that should be transferred, based on details from customer file upload
    #
    def wells_to_be_transferred
      @wells_to_be_transferred ||=
        labware_wells.filter_map { |well| well if request_metadata_details.key?(well.position['name']) }
    end

    #
    # Returns a hash of request metadata fields
    #
    def well_request_options(well_detail)
      REQUEST_METADATA_FIELDS.index_with { |field| well_detail[field] }
    end

    #
    # Each distinct asset grouping creates an order and request
    # Because we are storing well-speciific values in the request metadata like dilution volume, this method
    # currently creates an asset group for each well, which is not very efficient.
    # TODO: is there a more efficient way?
    #
    def generate_asset_groups(config_request_options)
      asset_groups = []

      wells_to_be_transferred.each do |well|
        well_coord = well.position['name']
        well_detail = request_metadata_details[well_coord]
        well_asset_group = {
          assets: [well.uuid],
          autodetect_studies_projects: true,
          request_options: config_request_options.merge(well_request_options(well_detail))
        }
        asset_groups << well_asset_group
      end
      asset_groups
    end

    #
    # Creates the dilution and cleanup submission
    #
    def create_submission(configured_params)
      config_request_options = configured_params[:request_options]

      # N.B. request options will be overridden in sequencescape_submission by the merge of asset groups,
      # but will trigger a validation error if not present
      sequencescape_submission_parameters = {
        template_name: configured_params[:template_name],
        request_options: {
          placeholder: 'will_be_overridden'
        },
        asset_groups: generate_asset_groups(config_request_options),
        api: api,
        user: user_uuid
      }

      ss = SequencescapeSubmission.new(sequencescape_submission_parameters)
      submission_created = ss.save

      if submission_created
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
      # refetch the parent wells so have submitted requests information
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
  # rubocop:enable Metrics/ClassLength
end

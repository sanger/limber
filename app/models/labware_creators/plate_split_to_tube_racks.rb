# frozen_string_literal: true

require_dependency 'form'
require_dependency 'labware_creators/base'

module LabwareCreators
  # Handles the creation of up to 2 child racks of tubes from a single parent 96-well plate.
  # Intended for use in a PBMC cell extraction pipeline.
  #
  # There will typically be one rack of tubes for 'contingency' and one for 'sequencing' (this rack is
  # optional).
  #
  # The parent plate contains multiple copies of material prepared from the same sample. One well instance
  # of each sample will go into a tube in the 'sequencing' rack (if present), and any remaining copies
  # will go into tubes in the 'contingency' rack.
  #
  # If after the initial preparation the users feel they need more contingency tubes, then they will go
  # back to prepare more material for that sample from an earlier step in the pipeline and create just
  # 'contingency' tubes at this step.
  #
  # Inputs:
  # 1) The parent plate - contains a number of wells containing material prepared from the same sample.
  #    The first of these parent wells will be transferred into a tube in the 'sequencing' rack if it is
  #    present, and any remaining parent wells for the same sample will be transferred into tubes in the
  #    'contingency' rack.
  # 2) Child tube rack scan CSV files - these are scans of racks of 2D tube barcodes from the 'contingency'
  #    and 'sequencing' tube racks, to allow us to know the position and barcode of each available tube.
  #    On the upload screen displays counts of how many tubes are needed (e.g. To perform this transfer you
  #    will either need 20 sequencing and 40 contingency tubes, or 60 contingency tubes.)
  #
  # Validations - Error message to users if any of these are not met:
  # 1) The user must always upload a scan file for the 'contingency' rack tube barcodes, whereas the
  #    'sequencing' rack file is optional.
  # 2) The scanned child tube barcodes must be unique and must not already exist in the system i.e. they are
  #    new unused empty tubes. List any that do already exist with rack type and location.
  # 3) The number of tubes available in the racks must be sufficient for the number of parent wells being
  #    transferred. e.g. if there are 20 distinct samples in the parent and 40 additional copies (60 wells
  #    total), then there must be at least 20 tubes in the first rack and at least 40 in the second rack.
  #    List any racks that do not have enough tubes with totals.
  #
  # rubocop:disable Metrics/ClassLength
  class PlateSplitToTubeRacks < Base
    include SupportParent::PlateOnly

    self.attributes += %i[sequencing_file contingency_file]

    self.page = 'plate_split_to_tube_racks'

    attr_accessor :sequencing_file, :contingency_file

    attr_reader :child_sequencing_tubes, :child_contingency_tubes

    validates_nested :well_filter

    # TODO: can add validations for specific metadata fields here if needed

    # Don't create the tubes until at least the contingency file has been uploaded
    validates :contingency_file, presence: true

    # N.B. contingency file is required, sequencing file is optional
    validates_nested :sequencing_csv_file, if: :contingency_file
    validates_nested :contingency_csv_file, if: :sequencing_file

    # validate there are sufficient tubes in the racks for the number of parent wells
    validate :sufficient_tubes_in_racks?

    # validate that the tube barcodes do not already exist in the system
    validate :tube_barcodes_are_unique?

    # TODO: check need all this in the includes e.g. metadata
    PARENT_PLATE_INCLUDES = 'wells.aliquots,wells.aliquots.sample,wells.aliquots.sample.sample_metadata'

    def save
      super && upload_tube_rack_files && true
    end

    def parent
      @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PARENT_PLATE_INCLUDES, uuid: parent_uuid)
    end

    def parent_v1
      @parent_v1 ||= api.plate.find(parent_uuid)
    end

    def filters=(filter_parameters)
      well_filter.assign_attributes(filter_parameters)
    end

    # Fetches the unfiltered list of wells from the parent plate
    def labware_wells
      parent.wells
    end

    def create_labware!
      @child_sequencing_tubes = create_child_sequencing_tubes
      @child_contingency_tubes = create_child_contingency_tubes
      perform_transfers
      true
    end

    def create_child_sequencing_tubes
      return [] if require_contingency_tubes_only?

      # TODO: want to also store seq rack barcode on the tubes
      create_tubes(sequencing_tube_purpose_uuid, parent_wells_for_sequencing.length, sequencing_tube_attributes)
    end

    def create_child_contingency_tubes
      # TODO: want to also store cont rack barcode on the tubes
      create_tubes(contingency_tube_purpose_uuid, parent_wells_for_contingency.length, contingency_tube_attributes)
    end

    def perform_transfers
      api.transfer_request_collection.create!(user: user_uuid, transfer_requests: transfer_request_attributes)
    end

    # We may create multiple tubes, so redirect to the parent plate
    def redirection_target
      parent
    end

    def anchor
      'children_tab'
    end

    # Validation that there are sufficient tubes in the racks for this parent plate.
    # This depends on the number of unique samples in the parent plate, and the number of parent wells,
    # as well as whether they are using both sequencing tubes and contingency tubes or just contingency.
    def sufficient_tubes_in_racks?
      return if contingency_file.blank?

      if require_contingency_tubes_only?
        num_contingency_tubes >= num_parent_wells
      else
        (num_sequencing_tubes >= num_parent_unique_samples) &&
          (num_contingency_tubes >= (num_parent_wells - num_parent_unique_samples))
      end
    end

    # Validation that the tube barcodes are unique and do not already exist in the system.
    def tube_barcodes_are_unique?
      check_tube_rack_scan_file(sequencing_csv_file, 'Sequencing') if sequencing_file.present?
      check_tube_rack_scan_file(contingency_csv_file, 'Contingency') if contingency_file.present?
    end

    def check_tube_rack_scan_file(tube_rack_file, msg_prefix)
      tube_rack_file.position_details.each do |tube_posn, tube_details|
        foreign_barcode = tube_details['barcode']
        tube_in_db = Sequencescape::Api::V2::Tube.find_by(barcode: foreign_barcode)
        next if tube_in_db.blank?

        msg = "#{msg_prefix} tube barcode #{foreign_barcode} (at rack position #{tube_posn}) already exists in the LIMS"
        errors.add(:tube_rack_file, msg)
      end
    end

    private

    def well_filter
      # filters failed and cancelled wells by default
      @well_filter ||= WellFilter.new(creator: self)
    end

    def num_parent_wells
      @num_parent_wells ||= well_filter.filtered.length
    end

    def ancestor_stock_tubes
      @ancestor_stock_tubes ||= locate_ancestor_tubes
    end

    #
    # Identify the originally supplied ancestor source tubes from their purpose name
    # and create a hash with sample uuid as the key
    # @return [Hash] e.g.
    # {
    #   <sample 1 uuid>: <tube 1>,
    #   <sample 2 uuid>: <tube 2>,
    #   etc.
    # }
    def locate_ancestor_tubes
      purpose_name = purpose_config[:ancestor_stock_tube_purpose_name]

      ancestor_results = parent.ancestors.where(purpose_name: purpose_name)
      return {} if ancestor_results.blank?

      ancestor_results.each_with_object({}) do |ancestor_result, tube_list|
        tube = Sequencescape::Api::V2::Tube.find_by(uuid: ancestor_result.uuid)
        tube_sample_uuid = tube.aliquots.first.sample.uuid
        tube_list[tube_sample_uuid] = tube if tube_sample_uuid.present?
      end
    end

    def parent_uniq_sample_uuids
      @parent_uniq_sample_uuids ||=
        well_filter
          .filtered
          .each_with_object({}) do |(well, _ignore), unique_sample_uuids|
            sample_uuid = well.aliquots.first.sample.uuid
            unique_sample_uuids[sample_uuid] = true unless sample_uuid.in?(unique_sample_uuids)
          end
    end

    # Parent will contain several wells per sample
    def num_parent_unique_samples
      @num_parent_unique_samples ||= parent_uniq_sample_uuids.keys.length
    end

    def num_sequencing_tubes
      # TODO: check this doesn't count NO READ or empty positions
      @num_sequencing_tubes ||= sequencing_csv_file&.position_details&.length || 0
    end

    def num_contingency_tubes
      @num_contingency_tubes ||= contingency_csv_file&.position_details&.length || 0
    end

    #
    # Upload the tube rack csv files onto the plate via api v1
    #
    def upload_tube_rack_files
      parent_v1.qc_files.create_from_file!(sequencing_file, 'scrna_core_sequencing_tube_rack_scan.csv')
      parent_v1.qc_files.create_from_file!(contingency_file, 'scrna_core_contingency_tube_rack_scan.csv')
    end

    #
    # Create class that will parse and validate the uploaded file
    def sequencing_csv_file
      @sequencing_csv_file ||= CsvFile.new(sequencing_file, parent.human_barcode)
    end

    def contingency_csv_file
      @contingency_csv_file ||= CsvFile.new(contingency_file, parent.human_barcode)
    end

    def require_contingency_tubes_only?
      sequencing_file.blank?
    end

    def parent_wells_for_sequencing
      @parent_wells_for_sequencing ||= find_parent_wells_for_sequencing
    end

    def find_parent_wells_for_sequencing
      unique_sample_uuids = []
      parent_wells_for_seq = []

      well_filter.filtered.each do |well, _ignore|
        sample_uuid = well.aliquots.first.sample.uuid
        next if sample_uuid.in?(unique_sample_uuids)

        unique_sample_uuids << sample_uuid
        parent_wells_for_seq << well
      end

      parent_wells_for_seq
    end

    def parent_wells_for_contingency
      @parent_wells_for_contingency ||=
        well_filter.filtered.filter_map { |well, _ignore| well unless parent_wells_for_sequencing.include?(well) }
    end

    def create_tubes(tube_purpose_uuid, number_of_tubes, tube_attributes)
      api
        .specific_tube_creation
        .create!(
          user: user_uuid,
          parent: parent_uuid,
          child_purposes: [tube_purpose_uuid] * number_of_tubes,
          tube_attributes: tube_attributes
        )
        .children
        .index_by(&:name)
    end

    def sequencing_tube_purpose_name
      @sequencing_tube_purpose_name ||= purpose_config.dig(:creator_class, :args, :child_seq_tube_purpose_name)
    end

    def sequencing_tube_purpose_uuid
      raise "Missing purpose configuration argument 'child_seq_tube_purpose_name'" unless sequencing_tube_purpose_name

      Settings.purpose_uuids[sequencing_tube_purpose_name]
    end

    def contingency_tube_purpose_name
      @contingency_tube_purpose_name ||= purpose_config.dig(:creator_class, :args, :child_spare_tube_purpose_name)
    end

    def contingency_tube_purpose_uuid
      unless contingency_tube_purpose_name
        raise "Missing purpose configuration argument 'child_spare_tube_purpose_name'"
      end

      Settings.purpose_uuids[contingency_tube_purpose_name]
    end

    def ancestor_tube_barcode(sample_uuid)
      sample_ancestor_tube = ancestor_stock_tubes[sample_uuid]
      if sample_ancestor_tube.blank?
        raise StandardError, "Failed to identify ancestor (supplier) source tube for sample uuid #{sample_uuid}"
      end

      sample_ancestor_tube.human_barcode
    end

    def sequencing_tube_attributes
      @sequencing_tube_attributes ||= generate_sequencing_tube_attributes
    end

    #
    # Create the tube attributes to send for the tubes creation in Sequencescape.
    # Passes the name for each tube.
    # Passes the foreign barcode extracted from the tube rack scan upload for each tube,
    # which on the Sequencescape side sets that barcode as the primary.
    #
    # returns [Array of hashes] e.g.
    # [
    #   {
    #     prefix: SPARE,
    #     name: NT11111111:A1,
    #     foreign_barcode: FD11111111
    #   },
    #   etc.
    # ]
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate_sequencing_tube_attributes
      # fetch the available tube positions (i.e. locations of scanned tubes for which we
      # have the barcodes) e.g. ["A1", "B1", "D1"]
      available_tube_positions = sequencing_csv_file.position_details.keys

      # used for building request hash later
      @sequencing_wells_to_tube_posns = {}

      parent_wells_for_sequencing
        .zip(available_tube_positions)
        .map do |well, tube_posn|
          sample_uuid = well.aliquots.first.sample.uuid

          # TODO: put prefixes in the purpose config
          name_for_details = name_for_details_hash('SEQ', ancestor_tube_barcode(sample_uuid), tube_posn)

          tube_name = name_for(name_for_details)
          @sequencing_wells_to_tube_posns[well] = tube_name

          { name: tube_name, foreign_barcode: sequencing_csv_file.position_details[tube_posn]['barcode'] }
        end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def contingency_tube_attributes
      @contingency_tube_attributes ||= generate_contingency_tube_attributes
    end

    #
    # Create the tube attributes to send for the tubes creation in Sequencescape.
    # Passes the name for each tube.
    # Passes the foreign barcode extracted from the tube rack scan upload for each tube,
    # which on the Sequencescape side sets that barcode as the primary.
    #
    # returns [Array of hashes] e.g.
    # [
    #   {
    #     prefix: SPARE,
    #     name: NT11111111:A1,
    #     foreign_barcode: FD11111111
    #   },
    #   etc.
    # ]
    #
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def generate_contingency_tube_attributes
      # fetch the available tube positions (i.e. locations of scanned tubes for which we
      # have the barcodes) e.g. ["A1", "B1", "D1"]
      available_tube_positions = contingency_csv_file.position_details.keys

      # used for building request hash later
      @contingency_wells_to_tube_posns = {}

      parent_wells_for_contingency
        .zip(available_tube_positions)
        .map do |well, tube_posn|
          sample_uuid = well.aliquots.first.sample.uuid

          # TODO: put prefixes in the purpose config
          name_for_details = name_for_details_hash('SPR', ancestor_tube_barcode(sample_uuid), tube_posn)

          tube_name = name_for(name_for_details)
          @contingency_wells_to_tube_posns[well] = tube_name

          { name: tube_name, foreign_barcode: contingency_csv_file.position_details[tube_posn]['barcode'] }
        end
    end

    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    def name_for_details_hash(prefix, stock_tube_bc, dest_tube_posn)
      { prefix: prefix, stock_tube_bc: stock_tube_bc, dest_tube_posn: dest_tube_posn }
    end

    #
    # Generates a name for the destination tube.
    # Comprises a prefix, the ancestor source (stock) tube barcode and the destination tube position
    # return [String] e.g. 'SEQ:NT12345678:A1'
    #
    def name_for(details)
      "#{details[:prefix]}:#{details[:stock_tube_bc]}:#{details[:dest_tube_posn]}"
    end

    def transfer_request_attributes
      well_filter.filtered.map do |well, additional_parameters|
        child_tube_name = @sequencing_wells_to_tube_posns[well]
        child_tube_name = @contingency_wells_to_tube_posns[well] if child_tube_name.blank?

        child_tube = @child_sequencing_tubes[child_tube_name]
        child_tube = @child_contingency_tubes[child_tube_name] if child_tube.blank?

        # TODO: add set tube rack barcode
        # tube_rack_barcode = sequencing_csv_file.tube_rack_barcode
        # add_tube_rack_barcode_metadata(child_tube, tube_rack_barcode)
        request_hash(well.uuid, child_tube.uuid, additional_parameters)
      end
    end

    # TODO: add tube rack barcode to tube metadata
    # def add_tube_rack_barcode_metadata(child_tube, tube_rack_barcode)
    #   # TODO: does this need to be .create! ?
    #   LabwareMetadata
    #     .new(api: api, user: user_uuid, barcode: tube.barcode.machine)
    #     .update!(tube_rack_barcode: tube_rack_barcode)
    # end

    def request_hash(source_well_uuid, target_tube_uuid, additional_parameters)
      { 'source_asset' => source_well_uuid, 'target_asset' => target_tube_uuid }.merge(additional_parameters)
    end

    # Maps well locations to the corresponding uuid
    #
    # @return [Hash] Hash with well locations (eg. 'A1') as keys, and uuids as values
    # def well_locations
    #   TODO: should get the wells from the well_filter.filtered method
    #   @well_locations ||= parent.wells.index_by(&:location)
    # end
  end
  # rubocop:enable Metrics/ClassLength
end

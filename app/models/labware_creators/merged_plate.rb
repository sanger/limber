# frozen_string_literal: true

module LabwareCreators
  # Merges plates together into a single child plate, and de-duplicates aliquots if they are identical.
  class MergedPlate < StampedPlate
    include LabwareCreators::CustomPage
    include CreatableFrom::PlateOnly

    attr_reader :child, :barcodes, :minimal_barcodes

    self.attributes += [{ barcodes: [] }]
    self.page = 'merged_plate'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, presence: true
    validate :all_source_barcodes_must_be_entered
    validate :source_plates_can_be_merged
    validate :source_barcodes_must_be_different
    validate :source_plates_must_have_expected_purposes

    delegate :size, :number_of_columns, :number_of_rows, to: :labware

    def labware_wells
      source_plates.flat_map(&:wells)
    end

    #
    # Returns the source plate purposes for use in the help view.
    #
    # @return [Array] Purpose name strings.
    #
    def expected_source_purposes
      Settings.purposes.dig(@purpose_uuid, :merged_plate).source_purposes
    end

    #
    # Returns specific help text to display to the user for this specific use case.
    #
    # @return [String] Some descriptive text.
    #
    def help_text
      Settings.purposes.dig(@purpose_uuid, :merged_plate).help_text
    end

    def barcodes=(barcodes)
      @barcodes = barcodes

      # Removes empty strings from barcodes, for validation and strips off whitespace
      @minimal_barcodes = barcodes.compact_blank.map(&:strip)
    end

    private

    def create_plate_from_parent!
      Sequencescape::Api::V2::PooledPlateCreation.create!(
        child_purpose_uuid: purpose_uuid,
        parent_uuids: source_plates.map(&:uuid),
        user_uuid: user_uuid
      )
    end

    def source_plates
      @source_plates ||=
        Sequencescape::Api::V2::Plate.find_all(
          { barcode: minimal_barcodes },
          includes: 'purpose,parents,wells.aliquots.request,wells.requests_as_source'
        )
    end

    # Returns the attributes for a transfer request from
    # source_well to the same location on child_plate
    # Unlike request_hash on StampedPlate sets the merge_equivalent_aliquots to true
    def request_hash(source_well, child_plate, additional_parameters)
      super.merge(merge_equivalent_aliquots: true)
    end

    # validation to check the number of barcodes scanned matches the number of expected purposes from the configuration
    def all_source_barcodes_must_be_entered
      return if minimal_barcodes.size == expected_source_purposes.size

      msg = 'Please scan in all the required source plate barcodes.'
      errors.add(:base, msg)
    end

    # Validation to check all source plates can be merged.
    # Currently we allow this if there is a maximum of one request associated with each well.
    # One library request covers both forks of the process, and is recorded on the aliquots, thus
    # if two aliquots are associated with the same request, they are part of the same process and can be
    # merged. Behind the scenes Sequencescape also checks a number of other attributes, such as
    # library_type and primer_panel_id, but as these are both set by the request, we can be pretty
    # confident that they'll match in this case.
    # The suboptimal flag is also included in the check, as this is exposed via the API, and forms
    # part of Sequencescape's de-duplication. In most cases this will be identical, however can differ
    # if users begin processing plates while the qc report is still running.
    # @see Sequencescape::Api::V2::Aliquot#equivalent_attributes for more information
    # Theoretically we can allow merging of plates with two distinct requests, as long as they have two
    # different tag sets. See #merge_index for details
    def source_plates_can_be_merged
      expected_merges = expected_merges(source_plates)

      return unless expected_merges.values.any? { |v| v.uniq.many? }

      errors.add(
        :source_plates,
        'have different requests or suboptimal status and can not be merged, ' \
        'please check you have scanned the correct set of source plates.'
      )
    end

    #
    # Build up a hash of all merges that we expect to resolve
    #
    # @param [Array] source_plates Array of {Sequencescape::Api::V2::Plate} to be merged
    #
    # @return [Hash] Hash of each well/tag combination as a key, with an array of associated aliquots information
    #                [request_id, suboptimal]
    #                @example { 'A1' => [['1', false],['1', false]] }
    #
    def expected_merges(source_plates)
      # Given the small set size, arrays are actually faster here than sets
      merges = Hash.new { |h, i| h[i] = [] }
      source_plates.each do |plate|
        plate.each_well_and_aliquot do |well, aliquot|
          merges[merge_index(well, aliquot)] << aliquot.equivalent_attributes
        end
      end
      merges
    end

    # All aliquots with the same merge_index should be capable of being merged.
    # Currently this is restricted to *all* aliquots in the same well location.
    # If this was changed to:
    # ```
    #  [well.position, aliquot.tag_pair]
    # ```
    # it would allow merging of plates for different requests, as long as their
    # tag groups are different. This functionality is currently disabled to prevent
    # it being used accidentally.
    def merge_index(well, _aliquot)
      well.position
    end

    # Validation to check the user hasn't scanned the same barcode multiple times
    def source_barcodes_must_be_different
      return unless minimal_barcodes.any? { |e| minimal_barcodes.count(e) > 1 }

      msg = 'should not have the same barcode, please check you scanned all the plates.'
      errors.add(:source_plates, msg)
    end

    # Validation to check the user hasn't accidentally created multiple plates with the same purpose
    def source_plates_must_have_expected_purposes
      actual_purposes = source_plates.map { |sp| sp.purpose[:name] }
      return if actual_purposes.sort == expected_source_purposes.sort

      msg = 'do not have the expected types, check whether the right set of plate types have been made.'
      errors.add(:source_plates, msg)
    end
  end
end

# frozen_string_literal: true

module LabwareCreators
  # Merges plates together into a single child plate, and de-duplicates aliquots if they are identical.
  class MergedPlate < StampedPlate
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    attr_reader :child
    attr_accessor :barcodes

    self.attributes += [{ barcodes: [] }]
    self.page = 'merged_plate'

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, presence: true
    validate :all_source_barcodes_entered?
    validate :source_plates_have_same_parent?
    validate :source_barcodes_are_different?
    validate :source_plates_have_expected_purposes?

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

    private

    # removes empty strings from barcodes, for validation
    def minimal_barcodes
      barcodes.reject { |e| e.to_s.empty? }
    end

    def create_plate_from_parent!
      api.pooled_plate_creation.create!(
        child_purpose: purpose_uuid,
        user: user_uuid,
        parents: source_plates.map(&:uuid)
      )
    end

    def source_plates
      @source_plates ||= Sequencescape::Api::V2::Plate.find_all(
        { barcode: minimal_barcodes },
        includes: 'purpose,parents,wells.aliquots.request,wells.requests_as_source'
      )
    end

    # Returns the attributes for a transfer request from
    # source_well to the same location on child_plate
    # Unlike request_hash on StampedPlate sets the merge_equivalent_aliquots to true
    def request_hash(source_well, child_plate, additional_parameters)
      super.merge('merge_equivalent_aliquots' => true)
    end

    # validation to check the number of barcodes scanned matches the number of expected purposes from the configuration
    def all_source_barcodes_entered?
      return if minimal_barcodes.size == expected_source_purposes.size

      msg = 'Please scan in all the required source plate barcodes.'
      errors.add(:parent, msg)
    end

    # Validation to check all source plates have the same parent
    def source_plates_have_same_parent?
      return if source_plates.map { |sp| sp.parents.map(&:id) }.flatten.uniq.one?

      msg = 'The source plates have different parents, please check you have scanned the correct set of source plates.'
      errors.add(:parent, msg)
    end

    # Validation to check the user hasn't scanned the same barcode multiple times
    def source_barcodes_are_different?
      duplicates = minimal_barcodes.select { |e| minimal_barcodes.count(e) > 1 }
      return if duplicates.uniq.empty?

      msg = 'The source plates should not have the same barcode, please check you scanned all the plates.'
      errors.add(:parent, msg)
    end

    # Validation to check the user hasn't accidently created multiple plates wirh the same purpose
    def source_plates_have_expected_purposes?
      actual_purposes = source_plates.map { |sp| sp.purpose[:name] }
      return if actual_purposes.sort == expected_source_purposes.sort

      msg = 'The source plates do not have the expected types, check whether the right set of plate types have been made.'
      errors.add(:parent, msg)
    end
  end
end

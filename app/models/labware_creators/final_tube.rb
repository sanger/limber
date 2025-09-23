# frozen_string_literal: true

module LabwareCreators
  # The final tubes form handles the transfer to the Multiplexed Library Tube
  # that gets generated upfront when the submission is made. It has two behaviours:
  # 1) For single plate pools it generates the new tube immediately
  # 2) For cross-plate pools (such as dual index) it prompts the user to scan
  #    all tubes in the submission
  # This check is based on the contents of sibling_tubes in the json
  class FinalTube < Base
    include CreatableFrom::TubeOnly

    self.default_transfer_template_name = 'Transfer from tube to tube by submission'
    self.page = 'final_tube'
    self.attributes += [{ parents: {} }]

    attr_reader :all_tube_transfers

    validate :all_parents_and_only_parents?, if: :barcodes_provided?
    validate :custom_input_expected, unless: :no_pooling_required?

    def each_sibling(&)
      siblings.each(&)
    end

    def all_ready?
      siblings.all?(&:ready?)
    end

    def create_labware!
      @all_tube_transfers = parents.map { |this_parent_uuid| transfer!(source_uuid: this_parent_uuid) }
      true
    end

    def custom_input_expected
      errors.add(:parent, 'has sibling tubes, which must be pooled.') unless barcodes_provided?
    end

    # We pretend that we've added a new blank tube when we're actually
    # transferring to the tube on the original LibraryRequest
    def redirection_target
      return :contents_not_transfered_to_mx_tube if all_tube_transfers.nil?

      # Return a single tube as a redirection target
      destination_uuids = all_tube_transfers.map(&:destination_uuid).uniq
      return Tube.new(destination_uuids.first) if destination_uuids.one?

      raise StandardError, 'Multiple targets found. You may have scanned tubes from separate submissions.'
    end

    def parents=(barcode_hash)
      return unless barcode_hash.respond_to?(:keys)

      @barcodes = barcode_hash.select { |_barcode, selected| selected == '1' }.keys
      @parents = @barcodes.map { |barcode| barcode_to_uuid(barcode) }
    end

    def parent
      return @parent if defined?(@parent)

      @parent = Sequencescape::Api::V2::Tube.find_by(uuid: parent_uuid)
    end
    alias tube parent

    def parents
      @parents || [parent_uuid]
    end

    private

    # Tubes siblings include themselves, so we expect to see just one sibling
    def no_pooling_required?
      parent.sibling_tubes.count == 1
    end

    def barcode_to_uuid(barcode)
      siblings.detect { |s| s.barcode == barcode }.uuid
    end

    def siblings
      @siblings ||= parent.sibling_tubes.map { |s| Sibling.new(s) }
    end

    def barcodes_provided?
      @barcodes.present?
    end

    def all_parents_and_only_parents?
      val_barcodes = @barcodes.dup
      valid = true
      siblings.each do |s|
        next if val_barcodes.delete(s.barcode)

        errors.add(
          :base,
          "Tube #{s.name} was missing. No transfer has been performed. This is a bug, as you should have been " \
          'prevented from getting this far.'
        )
        valid = false
      end
      return valid if val_barcodes.empty?

      errors.add(
        :base,
        "#{val_barcodes.join(', ')} are not valid. No transfer has been performed. This is a bug, as you should have " \
        'been prevented from getting this far.'
      )
      false
    end
  end
end

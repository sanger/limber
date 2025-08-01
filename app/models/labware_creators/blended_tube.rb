# frozen_string_literal: true

module LabwareCreators
  # Blends two parent tubes into a single child tube.
  #
  class BlendedTube < Base
    include LabwareCreators::CustomPage
    include CreatableFrom::TubeOnly

    class_attribute :transfers_creator

    # transfers are passed in from the Vue JS page
    self.attributes += [{ transfers: [%i[source_tube outer_request]] }]
    attr_accessor :transfers

    self.page = 'blended_tube'
    self.transfers_creator = 'blended-tube'

    validates :transfers, presence: true

    # Fetch the ancestor plate purpose type from purpose configuration
    def ancestor_labware_purpose_name
      purpose_config.dig(:creator_class, :args, :ancestor_labware_purpose_name)
    end

    def acceptable_parent_tube_purposes
      purpose_config.dig(:creator_class, :args, :acceptable_parent_tube_purposes).to_a
    end

    def single_ancestor_parent_tube_purpose
      purpose_config.dig(:creator_class, :args, :single_ancestor_parent_tube_purpose)
    end

    def preferred_purpose_name_when_deduplicating
      purpose_config.dig(:creator_class, :args, :preferred_purpose_name_when_deduplicating)
    end

    def list_of_aliquot_attributes_to_consider_a_duplicate
      purpose_config.dig(:creator_class, :args, :list_of_aliquot_attributes_to_consider_a_duplicate)
    end

    def redirection_target
      @child_tube
    end

    private

    def create_labware!
      @child_tube = create_child_tube
      perform_transfers
      true
    end

    def tube_attributes
      [{ name: parents.map(&:human_barcode).join(':') }]
    end

    def create_child_tube
      Sequencescape::Api::V2::SpecificTubeCreation
        .create!(
          child_purpose_uuids: [purpose_uuid],
          parent_uuids: parents.map(&:uuid),
          tube_attributes: tube_attributes,
          user_uuid: user_uuid
        )
        .children
        .first
    end

    def perform_transfers
      Sequencescape::Api::V2::TransferRequestCollection.create!(
        transfer_requests_attributes: transfer_request_attributes,
        user_uuid: user_uuid
      )
    end

    def parent_uuids_from_transfers
      transfers.pluck(:source_tube).uniq
    end

    def parents
      Sequencescape::Api::V2::Tube.find_all({ uuid: parent_uuids_from_transfers }, includes: 'receptacle,aliquots')
    end

    def transfer_request_attributes
      transfers.map { |transfer| request_hash(transfer) }
    end

    def request_hash(transfer)
      parent_tube = Sequencescape::Api::V2::Tube.find_by(uuid: transfer[:source_tube])

      {
        source_asset: parent_tube.uuid,
        target_asset: @child_tube.uuid,
        merge_equivalent_aliquots: true,
        list_of_aliquot_attributes_to_consider_a_duplicate: list_of_aliquot_attributes_to_consider_a_duplicate,
        keep_this_aliquot_when_deduplicating: parent_tube.purpose.name == preferred_purpose_name_when_deduplicating
      }
    end
  end
end

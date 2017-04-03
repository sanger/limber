# frozen_string_literal: true

module Forms
  class MultiPlatePoolingForm < CreationForm
    include Forms::Form::CustomPage
    self.page = 'multi_plate_pooling'
    self.aliquot_partial = 'custom_pooled_aliquot'

    self.attributes = %i(
      api purpose_uuid parent_uuid user_uuid
      transfers
    )

    private

    def create_labware!
      @plate_creation = api.pooled_plate_creation.create!(
        parents:        transfers.keys,
        child_purpose:  purpose_uuid,
        user:           user_uuid
      )

      api.bulk_transfer.create!(
        user:           user_uuid,
        well_transfers: well_transfers
      )

      yield(@plate_creation.child) if block_given?
      true
    end

    # Returns an array of a hash describing individual transfers
    # based on the input transfers. Example below:
    # {
    #   'source_uuid' => 'source-plate-uuid',
    #   'source_location' => 'A1',
    #   'destination_uuid' => child-plate-uuid,
    #   'destination_location' => 'A1'
    # }
    #
    # @return [Array<Hash>] Array of hashes describing each transfer
    #
    def well_transfers
      transfers = []
      each_well do |source_uuid, source_well, destination_uuid, destination_well|
        transfers << {
          'source_uuid' => source_uuid,
          'source_location' => source_well,
          'destination_uuid' => destination_uuid,
          'destination_location' => destination_well
        }
      end
      transfers
    end

    def each_well
      transfers.each do |source_uuid, well_well_transfers|
        well_well_transfers.each do |source_well, destination_well|
          yield(source_uuid, source_well, @plate_creation.child.uuid, destination_well)
        end
      end
    end
  end
end

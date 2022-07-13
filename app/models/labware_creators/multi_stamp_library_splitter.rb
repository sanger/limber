# frozen_string_literal: true

# Handles the generation of two 96-well child plates from up to four 96-well source plates.
# In the client, the user will be able to scan 1-4 96-wells plate barcodes to
# create a pair of 96-well plates.
# Transfers are the first 3 columns from each of the four sources, into sets of 3 columns
# on the destination (source 1 to columns 1-3, source 2 to columns 4-6, source 3 to columns 7-9,
# and source 4 to columns 10-12).
#
# Eg.
#
# Plate 1        Plate 2         Dest. Plate
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |A1|A2|A3      |A1|A2|A3       |P1A1|P1A2|P1A3|P2A1|P2A2|P2A3
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |B1|B2|B3      |B1|B2|B3       |P1B1|P1B2|P1B3|P2B1|P2B2|P2B3
# +--+--+--~  +  +--+--+--~  =>  +----+----+----+----+----+----~
# |C1|C2|C3      |C1|C2|C3       |P1C1|P1C2|P1C3|P2C1|P2C2|P2C3
# +--+--+--~     +--+--+--~      +----+----+----+----+----+----~
# |D1|D2|D3      |D1|D2|D3       |P1D1|P1D2|P1D3|P2D1|P2D2|P2D3
#
# The user must specify a volume value which will be recorded on each
# transfer request. The transfer creator logic 'with-volume' is implemented
# client side.

module LabwareCreators
  class MultiStampLibrarySplitter < MultiStamp # rubocop:todo Style/Documentation
    class_attribute :max_wells_count, :default_volume

    self.page = 'multi_stamp_library_splitter'

    self.transfers_layout = 'sequentialLibrarySplit'
    self.request_filter = 'submission-and-library-type'
    self.transfers_creator = 'with-volume'
    self.attributes += [
      { transfers: [[:source_plate, :source_asset, :outer_request, :pool_index, { new_target: :location }, :volume]] }
    ]
    self.target_rows = 8
    self.target_columns = 12
    self.source_plates = 4
    self.max_wells_count = 24

    def default_volume
      purpose_config.dig(:creator_class, :args, :default_volume)
    end

    #
    # We've created multiple plates, so we redirect to the parent.
    #
    # @return [Sequencescape::Api::V2::Plate] The parent plate
    def redirection_target
      parent
    end

    def anchor
      'children_tab'
    end

    def library_type_split_plate_purpose
      purpose_config.dig(:creator_class, :args, :library_type_split_plate_purpose)
    end

    def children_library_type_to_purpose_mapping
      unless library_type_split_plate_purpose
        raise "Missing purpose configuration argument 'library_type_split_plate_purpose'"
      end

      library_type_split_plate_purpose.each_with_object({}) do |val, memo|
        library_type = val[:library_type]
        plate_purpose_name = val[:plate_purpose]
        memo[library_type] = Settings.purpose_uuids[plate_purpose_name]
      end
    end

    private

    def request_hash(transfer, *args)
      # We might want to add the 'volume' key into a nested hash called 'metadata'
      super.merge('volume' => transfer[:volume])
    end
  end
end

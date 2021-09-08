# frozen_string_literal: true

# Handle the generation of a single plate from up to 96 source tubes.
# Transfer requests will be collected in column order starting from the first of
# the 96 tubes. The destination wells will be laid down in column order.

module LabwareCreators
  class MultiStampTubesArray < MultiStampTubes # rubocop:todo Style/Documentation
    self.transfers_layout = 'sequential'
    # self.transfers_creator = 'with-volume'
    self.attributes += [
      {
        transfers: [
          [:source_plate, :source_asset, :outer_request, :pool_index, { new_target: :location }, :volume]
        ]
      }
    ]
    self.target_rows = 8
    self.target_columns = 12
    self.source_tubes = 96

    private

    # def request_hash(transfer, *args)
    #   # We might want to add the 'volume' key into a nested hash called 'metadata'
    #   super.merge('volume' => transfer[:volume])
    # end
  end
end

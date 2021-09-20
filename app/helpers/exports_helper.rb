# frozen_string_literal: true

# Helper methods for the Exports controller
module ExportsHelper
  def each_source_metadata_for_plate(plate)
    index = 0
    plate.wells_in_columns.each do |well|
      well.transfer_requests_as_target.each do |transfer_req|
        # NB. Making assumption here that name field on asset is for a plate well
        # and contains a plate barcode and well location e.g. DN12345678:A1
        name_array = transfer_req.source_asset.name.split(':')
        if name_array.length == 2
          yield well, index, name_array[0], name_array[1]
          index += 1
        end
      end
    end
  end
end

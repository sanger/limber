# frozen_string_literal: true

# Handle the generation of 10x 96-wells plates.
# In the client, the user will be able to scan 10 96-wells plate barcodes to
# create a single 96-well plate. Transfer requests will be collected in column
# order starting from the first of the 10 plates. The destination wells will be
# laid down in column order.
#
# Eg.
#
# Plate 1        Plate 2         Dest. Plate
# +--+--+--~     +--+--+--~      +----+----+----~
# |A1|  |A3      |A1|  |         |P1A1|P1A3|P2D2
# +--+--+--~     +--+--+--~      +----+----+----~
# |  |  |        |  |B2|B3       |P1C1|P1D3|P2B3
# +--+--+--~  +  +--+--+--~  =>  +----+----+----~
# |C1|C2|        |  |  |         |P1D1|P2A1|P2D3
# +--+--+--~     +--+--+--~      +----+----+----~
# |D1|  |D3      |  |D2|D3       |P1C2|P2B2|
#
# The user must specify a volume value which will be recorded on each
# transfer request. The transfer creator logic 'with-volume' is implemented
# client side.

module LabwareCreators
  class TenStamp < MultiStamp
    self.transfers_layout = 'sequential'
    self.transfers_creator = 'with-volume'
    self.transfers_attributes += [:volume]
    self.target_rows = 8
    self.target_columns = 12
    self.source_plates = 10

    private

    def request_hash(transfer, *args)
      # We might want to add the 'volume' key into a nested hash called 'metadata'
      super.merge('volume' => transfer[:volume])
    end
  end
end

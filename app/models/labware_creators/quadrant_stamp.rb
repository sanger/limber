# frozen_string_literal: true

module LabwareCreators
  # Basic quadrant stamp behaviour, applies no special request filters
  # See MultiStamp for further documentation
  #
  # Handles the generation of 384 well plates from 1-4 96 well plates.
  #
  # Briefly, 96 well plates get stamped onto 384 plates in an interpolated pattern
  # eg.
  # +--+--+--+--+--+--+--~
  # |P1|P3|P1|P3|P1|P3|P1
  # |A1|A1|A2|A2|A3|A3|A4
  # +--+--+--+--+--+--+--~
  # |P2|P4|P2|P4|P2|P4|P1
  # |A1|A1|A2|A2|A3|A3|A4
  # +--+--+--+--+--+--+--~
  # |P1|P3|P1|P3|P1|P3|P1
  # |B1|B1|B2|B2|B3|B3|B4
  # +--+--+--+--+--+--+--~
  # |P2|P4|P2|P4|P2|P4|P1
  # |B1|B1|B2|B2|B3|B3|B4
  #
  # The transfers layout 'quadrant' descibed above is implemented client side.
  #
  class QuadrantStamp < MultiStamp
    self.transfers_layout = 'quadrant'
    self.target_rows = 16
    self.target_columns = 24
    self.source_plates = 4
  end
end

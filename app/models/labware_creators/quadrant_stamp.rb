# frozen_string_literal: true

module LabwareCreators
  class QuadrantStamp < MultiStamp
    self.transfers_layout = 'quadrant'
    self.target_rows = 16
    self.target_columns = 24
    self.source_plates = 4
  end
end

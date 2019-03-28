# frozen_string_literal: true

module LabwareCreators
  class TenStamp < MultiStamp
    self.transfers_layout = 'sequential'
    self.target_rows = 8
    self.target_columns = 12
    self.source_plates = 10
  end
end

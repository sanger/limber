# frozen_string_literal: true

# This specialisation of MultiStamp is essentially like QuadrantStamp with the
# only difference that requests are filtered by primer panel.
# The filtering logic is implemented client side but essentially it will keep
# only the requests with a primer panel selected by the user.

module LabwareCreators
  class QuadrantStampPrimerPanel < MultiStamp
    self.request_filter = 'primer-panel'
    self.transfers_layout = 'quadrant'
    self.target_rows = 16
    self.target_columns = 24
    self.source_plates = 4
  end
end

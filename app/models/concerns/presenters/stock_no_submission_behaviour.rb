# frozen_string_literal: true

# Include in a presenter which handles stock plates that don't require submissions
module Presenters::StockNoSubmissionBehaviour
  extend ActiveSupport::Concern

  include Presenters::StateInputNoSubmission

  included { validates_with Validators::StockNoSubmissionStateValidator, if: :pending? }

  def input_barcode
    barcode
  end
end

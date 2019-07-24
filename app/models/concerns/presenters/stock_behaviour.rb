# frozen_string_literal: true

# Include in a presenter which handle stock plates
module Presenters::StockBehaviour
  extend ActiveSupport::Concern
  included do
    validates_with Validators::StockStateValidator, if: :pending?
  end

  def input_barcode
    barcode
  end

  def control_state_change
    # You cannot change the state of the stock plate
  end

  def default_state_change
    # You cannot change the state of the stock plate
  end
end

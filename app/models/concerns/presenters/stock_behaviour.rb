# frozen_string_literal: true

# Include in a presenter which handle stock plates
module Presenters::StockBehaviour
  extend ActiveSupport::Concern
  include Presenters::StateChangeless

  included { validates_with Validators::StockStateValidator, if: :pending? }

  def input_barcode
    barcode
  end
end

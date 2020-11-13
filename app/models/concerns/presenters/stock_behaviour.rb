# frozen_string_literal: true

# Include in a presenter which handle stock plates
module Presenters::StockBehaviour
  extend ActiveSupport::Concern
  include Presenters::StateChangeless

  included do
    validates_with Validators::StockStateValidator, if: :pending?
  end

  def input_barcode
    barcode
  end
end

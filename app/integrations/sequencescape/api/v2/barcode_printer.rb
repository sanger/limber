# frozen_string_literal: true

# barcode printer resource
class Sequencescape::Api::V2::BarcodePrinter < Sequencescape::Api::V2::Base
  # Cache the list of all printers to reduce needless API calls.
  def self.all
    Rails.cache.fetch('barcode_printers.all', expires_in: 3.minutes) do
      super()
    end
  end
end

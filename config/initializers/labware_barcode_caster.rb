# frozen_string_literal: true

require_dependency 'labware_barcode'

# Takes labware barcodes from the API and wraps them
class LabwareBarcodeCaster
  def self.cast(value, _default)
    LabwareBarcode.new(
      human: value['human_barcode'],
      machine: (value['machine_barcode'] || value['ean13_barcode']).to_s,
      ean13: value['ean13_barcode'].to_s
    )
  end
end

JsonApiClient::Schema.register barcode: LabwareBarcodeCaster

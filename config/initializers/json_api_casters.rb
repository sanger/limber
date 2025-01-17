# frozen_string_literal: true

require_dependency 'labware_barcode'

# Takes labware barcodes from the API and wraps them
class LabwareBarcodeCaster
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.cast(value, _default)
    return nil if value.nil?
    return value if value.is_a?(LabwareBarcode)
    return value if value.is_a?(String) && value.blank?

    LabwareBarcode.new(
      human: value['human_barcode'],
      machine: (value['machine_barcode'] || value['ean13_barcode'])&.to_s,
      ean13: value['ean13_barcode']&.to_s
    )
  end

  # rubocop:enable Metrics/CyclomaticComplexity
end

# Takes strings, and allows them to be queries with .string_value?
class StringInquirerCaster
  def self.cast(value, default)
    return nil unless value || default

    ActiveSupport::StringInquirer.new(value || default)
  end
end

JsonApiClient::Schema.register barcode: LabwareBarcodeCaster
JsonApiClient::Schema.register string_inquirer: StringInquirerCaster

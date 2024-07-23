# frozen_string_literal: true

FactoryBot.define do
  # Build an API v2 JSONAPI barcode printer.
  factory :v2_barcode_printer, class: Sequencescape::Api::V2::BarcodePrinter do
    skip_create
    type { 'barcode_printers' }
    uuid
    sequence(:id, &:to_s)
    sequence(:name) { |n| "Barcode Printer #{n}" }
    print_service { 'PMB' }
    type_name { nil }

    factory :v2_plate_barcode_printer do
      type_name { '96 Well Plate' }
    end

    factory :v2_tube_barcode_printer do
      type_name { '1D Tube' }
    end
  end
end

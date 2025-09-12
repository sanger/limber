# frozen_string_literal: true

class Labels::PlateSplit < Labels::PlateLabelXpBase # rubocop:todo Style/Documentation
  attr_writer :stock_plate_barcode

  def attributes
    super.merge(top_right: stock_plate_barcode)
  end

  def qc_label_definitions
    [super[0].merge(top_right: stock_plate_barcode)]
  end

  def stock_plate_barcode
    @stock_plate_barcode ||= stock_plate_barcode_getter
  end

  private

  def stock_plate_barcode_getter
    metadata = LabwareMetadata.new(barcode: labware.barcode.machine).metadata
    barcode = 'N/A'
    barcode = metadata.fetch('stock_barcode', barcode) unless metadata.nil?
    barcode
  rescue JsonApiClient::Errors::NotFound
    # A labware cannot be found for the barcode
    nil
  end
end

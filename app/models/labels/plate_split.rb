# frozen_string_literal: true

class Labels::PlateSplit < Labels::PlateLabelXpBase

  attr_accessor :stock_plate_barcode

  def attributes
    super.merge(top_right: stock_plate_barcode)
  end

  def qc_attributes
    super.merge(top_right: stock_plate_barcode)
  end

  def stock_plate_barcode
    @stock_plate_barcode ||= stock_plate_barcode_getter
  end

  private

  def stock_plate_barcode_getter
    api = Sequencescape::Api.new(Limber::Application.config.api.v1.connection_options.dup)
    metadata = PlateMetadata.new(api: api, barcode: labware.barcode.machine).metadata
    barcode = 'N/A'
    barcode = metadata.fetch('stock_barcode', barcode) unless metadata.nil?
    return barcode
  end
end

# frozen_string_literal: true

class Labels::PlateSplit < Labels::PlateLabelXpBase # rubocop:todo Style/Documentation
  attr_writer :stock_plate_barcode

  def attributes
    super.merge(top_right: stock_plate_barcode)
  end

  def qc_attributes
    [super[0].merge(top_right: stock_plate_barcode)]
  end

  def stock_plate_barcode
    @stock_plate_barcode ||= stock_plate_barcode_getter
  end

  private

  def stock_plate_barcode_getter
    api = Sequencescape::Api.new(Limber::Application.config.api.v1.connection_options.dup)
    metadata = LabwareMetadata.new(api: api, barcode: labware.barcode.machine).metadata
    barcode = 'N/A'
    barcode = metadata.fetch('stock_barcode', barcode) unless metadata.nil?
    barcode
  end
end

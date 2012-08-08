module BarcodeLabelsHelper
  def individual_barcode_printing_form(barcode, locals)
    render(:partial => 'labware/individual_barcode_printing_form', :locals => locals.merge(:barcode => barcode))
  end

  def multiple_barcodes_printing_form(barcodes, locals)
    render(:partial => 'labware/multiple_barcodes_printing_form', :locals => locals.merge(:barcodes => barcodes))
  end

  # Returns a list of printers applicable to the specified barcode.
  def printers_applicable_to(barcodes)
    barcode_types = Array(barcodes).map(&:type).uniq
    @printers.select { |p| barcode_types.include?(p.type.layout) }
  end

  def useful_barcode(barcode)
    "#{barcode.prefix}#{barcode.number} <em>#{barcode.ean13}</em>".html_safe
  end
end

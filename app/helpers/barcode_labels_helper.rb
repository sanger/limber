# frozen_string_literal: true

module BarcodeLabelsHelper
  def barcode_printing_form(locals)
    barcode_types = locals[:labels].map(&:type)
    printers = printers_of_type(barcode_types)
    print_job = PrintJob.new(
      number_of_copies: Settings.printers['default_count'],
      printer_name: @presenter.default_printer,
      printer_type: printers.first.type.name
    )
    render(partial: 'labware/barcode_printing_form', locals: locals.merge(print_job: print_job, printers: printers))
  end

  # Returns a list of printers applicable to the specified barcode.
  def printers_applicable_to(barcodes)
    printers_of_type(Array(barcodes).map(&:type).uniq)
  end

  def printers_of_type(barcode_types)
    @printers.select { |printer| barcode_types.include?(printer.type.layout) }
  end

  def useful_barcode(barcode)
    return 'Unknown' if barcode.nil?
    "#{barcode.prefix}#{barcode.number} <em>#{barcode.ean13}</em>".html_safe
  end
end

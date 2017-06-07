# frozen_string_literal: true

module BarcodeLabelsHelper
  def barcode_printing_form(labels:, redirection_url:, default_printer_name: @presenter.default_printer)
    barcode_types = labels.map(&:type)
    printers = printers_of_type(barcode_types)
    print_job = PrintJob.new(
      number_of_copies: Settings.printers['default_count'],
      printer_name: default_printer_name,
      printer_type: printers.first.type.name
    )
    locals = { print_job: print_job, printers: printers, labels: labels, redirection_url: redirection_url }
    render(partial: 'labware/barcode_printing_form', locals: locals)
  end

  def printers_of_type(barcode_types)
    @printers.select { |printer| barcode_types.include?(printer.type.layout) }
  end

  def useful_barcode(barcode)
    return 'Unknown' if barcode.nil?
    "#{barcode.prefix}#{barcode.number} <em>#{barcode.ean13}</em>".html_safe
  end
end

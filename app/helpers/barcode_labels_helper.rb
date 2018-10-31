# frozen_string_literal: true

module BarcodeLabelsHelper
  def barcode_printing_form(labels:, redirection_url:, default_printer_name: @presenter.default_printer)
    # labels are Labels::PlateLabel or Labels::TubeLabel so you can get the
    # default layout based on the such class
    printer_types = labels.map(&:printer_type)
    printers = printers_of_type(printer_types)
    print_job = PrintJob.new(
      number_of_copies: Settings.printers['default_count'],
      printer_name: default_printer_name,
      label_template: labels.first.label_template
    )
    locals = { print_job: print_job, printers: printers, labels: labels, redirection_url: redirection_url }
    render(partial: 'labware/barcode_printing_form', locals: locals)
  end

  def printers_of_type(printer_types)
    @printers.select { |printer| printer_types.include?(printer.type.name) }
  end

  def useful_barcode(barcode)
    return 'Unknown' if barcode.nil?

    "#{barcode.prefix}#{barcode.number} <em>#{barcode.ean13}</em>".html_safe
  end
end

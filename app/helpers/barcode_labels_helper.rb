# frozen_string_literal: true

module BarcodeLabelsHelper # rubocop:todo Style/Documentation
  def barcode_printing_form(
    labels:,
    redirection_url:,
    default_printer_name: @presenter.default_printer # rubocop:todo Rails/HelperInstanceVariable
  )
    # labels are Labels::PlateLabel or Labels::TubeLabel so you can get the
    # default layout based on the class
    printer_types = labels.map(&:printer_type)
    printers = printers_of_type(printer_types)

    print_job =
      PrintJob.new(
        number_of_copies: Settings.printers[:default_count],
        printer_name: default_printer_name,
        label_templates_by_service: JSON.generate(labels.first.label_templates_by_service)
      )

    # Is redirection_url needed?
    locals = { print_job:, printers:, labels:, redirection_url: }
    render(partial: 'labware/barcode_printing_form', locals: locals)
  end

  def printers_of_type(printer_types)
    @printers.select { |printer| printer_types.include?(printer.barcode_type) } # rubocop:todo Rails/HelperInstanceVariable
  end

  def useful_barcode(barcode)
    return 'Unknown' if barcode.nil?

    # Support for old API
    human_readable = barcode.try(:human) || "#{barcode.prefix}#{barcode.number}"

    if human_readable == barcode.machine
      human_readable
    else
      "#{human_readable} <em>#{barcode.machine}</em>".html_safe # rubocop:todo Rails/OutputSafety
    end
  end
end

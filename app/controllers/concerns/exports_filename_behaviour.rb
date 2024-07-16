# frozen_string_literal: true

# Helper methods for the Exports controllers
module ExportsFilenameBehaviour
  # Builds and returns the filename and file extension for the export
  def set_filename(labware, page)
    # The filename falls back to the csv template attribute if no filename is provided.
    filename = export.filename&.fetch('name', nil) || export.csv
    filename = build_filename(filename, labware, page)
    file_extension = export.file_extension || 'csv'
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.#{file_extension}\""
  end

  private

  def build_filename(filename, labware, page)
    # Append or prepend the given barcodes to the filename if specified in the export configuration.
    filename = handle_filename_barcode(filename, labware, export.filename&.fetch('labware_barcode', nil))
    filename =
      handle_filename_barcode(filename, labware.parents&.first, export.filename&.fetch('parent_labware_barcode', nil))

    # Append the page number to the filename if specified in the export configuration.
    filename += "_#{page + 1}" if export.filename&.fetch('include_page', false)
    filename
  end

  def handle_filename_barcode(filename, labware, options)
    return filename if options.blank? || labware.blank?

    barcode = labware.barcode.human
    filename = "#{barcode}_#{filename}" if options['prepend']
    filename = "#{filename}_#{barcode}" if options['append']
    filename
  end
end

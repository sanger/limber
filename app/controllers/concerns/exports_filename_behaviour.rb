# frozen_string_literal: true

# Helper methods for the Exports controllers
module ExportsFilenameBehaviour
  # Builds and returns the filename and file extension for the export
  def set_filename(labware, page) # rubocop:todo Metrics/AbcSize
    # The filename falls back to the csv template attribute if no filename is provided.
    filename = export.filename&.fetch('name', nil) || export.csv

    # Default to the Standard handler if none is specified
    handler = export.filename&.fetch('handler', 'Standard')
    handler_class = "Exports::FilenameHandler::#{handler}".constantize

    filename = handler_class.build_filename(filename, labware, page, export)
    file_extension = export.file_extension || 'csv'
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.#{file_extension}\""
  end
end

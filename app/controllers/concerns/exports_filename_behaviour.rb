# frozen_string_literal: true

# Helper methods for the Exports controllers
module ExportsFilenameBehaviour
  # Builds and returns the filename and file extension for the export
  def set_filename(labware, page)
    # Default to the Standard handler if none is specified
    handler = export.filename&.fetch('handler', 'Standard') || 'Standard'
    handler_class = "Exports::FilenameHandler::#{handler}".constantize

    filename = handler_class.build_filename(labware, page, export)
    file_extension = export.file_extension || 'csv'
    response.headers['Content-Disposition'] = "attachment; filename=\"#{filename}.#{file_extension}\""
  end
end

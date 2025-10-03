# frozen_string_literal: true

module Exports
  module FilenameHandler
    # Handles the standard filename behaviour
    class Standard
      def self.build_filename(filename, labware, page, export)
        # Append or prepend the given barcodes to the filename if specified in the export configuration.
        filename = handle_filename_barcode(filename, labware, export.filename&.fetch('labware_barcode', nil))
        filename =
          handle_filename_barcode(filename, labware.parents&.first,
                                  export.filename&.fetch('parent_labware_barcode', nil))

        # Append the page number to the filename if specified in the export configuration.
        filename += "_#{page + 1}" if export.filename&.fetch('include_page', false)
        filename
      end

      def self.handle_filename_barcode(filename, labware, options)
        return filename if options.blank? || labware.blank?

        barcode = labware.barcode.human
        filename = "#{barcode}_#{filename}" if options['prepend']
        filename = "#{filename}_#{barcode}" if options['append']
        filename
      end
    end
  end
end

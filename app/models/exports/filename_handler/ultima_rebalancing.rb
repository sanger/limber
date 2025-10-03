# frozen_string_literal: true

module Exports
  module FilenameHandler
    # Handles the filename for the Ultima Rebalancing export
    class UltimaRebalancing
      def self.build_filename(_filename, labware, _page, _export)
        batch_ids = labware.aliquots.collect do |aliquot|
          aliquot.poly_metadata.find { |pm| pm.key == 'batch_id' }&.value
        end

        # If there are no batch_ids, return the default filename
        return "Ultima_Rebalancing_#{labware.barcode.human}" if batch_ids.compact.empty?

        batch_ids.uniq.join('_').to_s
      end
    end
  end
end

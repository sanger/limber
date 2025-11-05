# frozen_string_literal: true

module Exports
  module FilenameHandler
    # Handles the filename for the Ultima Rebalancing export
    class UltimaRebalancing
      def self.build_filename(labware, _page, _export)
        batch_ids = labware.aliquots.collect do |aliquot|
          aliquot.poly_metadata.find { |pm| pm.key == 'batch_id' }&.value
        end

        # If there are no batch_ids, return the default filename
        file = "Ultima_rebalancing_#{labware.barcode.human}"
        file += "_#{batch_ids.uniq.join('_')}" unless batch_ids.compact.empty?
        file
      end
    end
  end
end

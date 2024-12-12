# frozen_string_literal: true

# Helper module for tube rack views
module TubeRackHelper
  def racked_tube_tooltip(tube, location)
    return location if tube.nil?

    "#{location}: #{tube.purpose_name} #{tube.name} #{tube.labware_barcode.human}"
  end
end

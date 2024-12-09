# frozen_string_literal: true

# Helper module for tube rack views
module TubeRackHelper
  def racked_tube_tooltip(tube, location)
    return location if tube.nil?

    new_line = '&#010;'
    "#{location}: #{tube.name}#{new_line}#{tube.labware_barcode.human}"
  end
end

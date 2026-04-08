# frozen_string_literal: true

# QC results are generated elsewhere, such as through QuantHub. They comprise
# a key (eg. molarity), representing the property being measured, a value
# and a unit. Assay type and assay version track metadata about how the QC was
# performed.
class Sequencescape::Api::V2::QcResult < Sequencescape::Api::V2::Base
  # Returns a Unit, which encapsulates both the scale and the units.
  # Allows us to handle QC results which may be recorded in two different
  # units
  #
  # @return [Unit] Combines the scalar value and units to allow for conversion
  #                https://github.com/olbrich/ruby-units
  #
  def unit_value
    Unit.new(value, units)
  end
end

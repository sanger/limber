# frozen_string_literal: true

module LabwareHelper # rubocop:todo Style/Documentation
  def state_change_form(presenter)
    render partial: 'labware/state_change', locals: { presenter: }
  end

  def simple_state_change_form(presenter)
    render partial: 'labware/simple_state_change', locals: { presenter: }
  end

  STANDARD_COLOURS = (1..384).map { |i| "colour-#{i}" }
  FAILED_STATES = %w[failed cancelled].freeze

  def self.cycling_colours(name)
    define_method(:"#{name}_colour") do |*args|
      return 'failed' if FAILED_STATES.include?(args.first) # First argument is always the well

      @colours ||= Hash.new { |h, k| h[k] = STANDARD_COLOURS.dup }
      @rotating ||=
        Hash.new do |h, k|
          h[k] = @colours[name].rotate!.last # rubocop:todo Rails/HelperInstanceVariable
        end
      @rotating[yield(*args)] # rubocop:todo Rails/HelperInstanceVariable
    end
  end

  cycling_colours(:bait) { |labware, _| labware.bait }
  cycling_colours(:pooling) { |_labware, destination| destination }

  def failable?(container)
    container.passed? && container.control_info != 'negative'
  end

  def prevent_well_fail?(container)
    !container.passed?
  end

  def colours_by_location
    return @location_colours if @location_colours.present? # rubocop:todo Rails/HelperInstanceVariable

    @location_colours = {} # rubocop:todo Rails/HelperInstanceVariable

    ('A'..'H').each_with_index do |row, row_index|
      (1..12).each_with_index do |col, col_index|
        @location_colours[row + col.to_s] = # rubocop:todo Rails/HelperInstanceVariable
          "colour-#{(col_index * 8) + row_index + 1}"
      end
    end

    @location_colours # rubocop:todo Rails/HelperInstanceVariable
  end

  def labware_by_state(labwares)
    labwares.group_by(&:state)
  end
end

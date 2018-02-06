# frozen_string_literal: true

module LabwareHelper
  def state_change_form(presenter)
    render partial: 'labware/state_change', locals: { presenter: presenter }
  end

  def simple_state_change_form(presenter)
    render partial: 'labware/simple_state_change', locals: { presenter: presenter }
  end

  STANDARD_COLOURS = (1..96).map { |i| "colour-#{i}" }
  FAILED_STATES    = %w[failed cancelled].freeze

  def self.cycling_colours(name, &block)
    define_method(:"#{name}_colour") do |*args|
      return 'failed' if FAILED_STATES.include?(args.first) # First argument is always the well
      @colours  ||= Hash.new { |h, k| h[k] = STANDARD_COLOURS.dup }
      @rotating ||= Hash.new { |h, k| h[k] = @colours[name].rotate!.last } # Go for last as it was first before the rotate
      @rotating[block.call(*args)]
    end
  end

  cycling_colours(:bait)    { |labware, _|            labware.bait }
  cycling_colours(:tag)     { |labware, _|            labware.pool_id }
  cycling_colours(:pooling) { |_labware, destination| destination }

  def show_state?(state, presenter, transitions)
    [presenter.labware.state, transitions.first.to].include?(state)
  end

  def self.disable_based_on_state(state_name)
    define_method(:"disable_#{state_name}_by_state") do |transitions, options|
      options ||= {}
      return { disabled: true }.merge(options) unless transitions.first.to == state_name.to_s
      {}.merge(options)
    end
  end

  disable_based_on_state(:cancelled)
  disable_based_on_state(:failed)

  def pool_colour_for_well(presenter, well)
    return 'permanent-failure' if well.state == 'failed'
    tube_uuid = presenter.transfers[well.location].uuid
    pooling_colour(well, tube_uuid)
  end

  # def aliquot_colour(labware)
  #   case labware.state
  #   when 'passed'   then 'green'
  #   when 'started'  then 'orange'
  #   when 'failed'   then 'red'
  #   when 'canceled' then 'red'
  #   else 'blue'
  #   end
  # end

  def permanent_state(container)
    return 'permanent-failure' if container.state == 'failed'
    'good'
  end

  def failable?(container)
    container.state == 'passed'
  end

  def colours_by_location
    return @location_colours if @location_colours.present?

    @location_colours = {}

    ('A'..'H').each_with_index do |row, row_index|
      (1..12).each_with_index do |col, col_index|
        @location_colours[row + col.to_s] = "colour-#{(col_index * 8) + row_index + 1}"
      end
    end

    @location_colours
  end

  def column(well)
    (location = well.try(:location)) || return
    (column = location.match(/^[A-H](\d[0-2]?)$/).try(:[], 1)) || return

    "plate-col-#{column}"
  end

  def labware_by_state(labwares)
    labwares.group_by(&:state)
  end

  def well_state_value(container)
    container.state == 'failed' ? 'permanent-failure' : container.state
  end

  def labware_type_and_state
    "#{@presenter.purpose.name}.#{@presenter.labware.state.downcase}"
  end

  def creation_partial_for(type)
    case type.downcase
    when 'tube' then 'labware/tubes/creation_button'
    when 'plate' then 'labware/plates/creation_button'
    # If we're here, something has gone wrong.
    # I'm not throwing an exception though as the user may not
    # even want to create the broken plate/tube
    else 'labware/unknown_type'
    end
  end
end

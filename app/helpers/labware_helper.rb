module LabwareHelper
  def state_change_form(presenter)
    render :partial => 'labware/state_change', :locals => { :presenter => presenter }
  end

  STANDARD_COLOURS = (1..96).map { |i| "colour-#{i}" }
  FAILED_STATES    = [ 'failed', 'cancelled' ]

  def self.cycling_colours(name, &block)
    define_method(:"#{name}_colour") do |*args|
      return 'failed' if FAILED_STATES.include?(args.first)  # First argument is always the well
      @colours  ||= Hash.new { |h,k| h[k] = STANDARD_COLOURS.dup }
      @rotating ||= Hash.new { |h,k| h[k] = @colours[name].rotate!.first }
      @rotating[block.call(*args)]
    end
  end

  cycling_colours(:bait)    { |labware, _|            labware.bait }
  cycling_colours(:tag)     { |labware, _|            labware.pool_id }
  cycling_colours(:pooling) { |labware, destination|  destination }

  def show_state?(state, presenter, transitions)
    [presenter.labware.state, transitions.first.to].include?(state)
  end

  def self.disable_based_on_state(state_name)
    define_method(:"disable_#{state_name}_by_state") do |transitions|
      return {:disabled => true} unless transitions.first.to == state_name.to_s
      {}
    end
  end

  disable_based_on_state(:cancelled)
  disable_based_on_state(:failed)

  def pool_colour_for_well(presenter, well)
    return 'permanent-failure' if well.state == 'failed'

    tube_uuid = presenter.transfers[well.location].uuid
    pooling_colour(well, tube_uuid)
  end

  def aliquot_colour(labware)
    case labware.state
      when "passed"   then "green"
      when "started"  then "orange"
      when "failed"   then "red"
      when "canceled" then "red"
      else "blue"
    end
  end

  def permanent_state(container)
    return "permanent-failure" if container.state == "failed"
    "good"
  end

  def admin_page?
    controller.controller_path.start_with? "admin"
  end

  def admin_link(presenter)
    return nil if presenter.class == Presenters::StockPlatePresenter

    @admin_link ||= link_to(
      'Admin',
      edit_admin_plate_path(presenter.labware.uuid),
      :id           => presenter.labware.uuid,
      :'data-transition' => 'pop',
      :'data-icon'  => 'gear',
      :rel          => "external"
    )
  end

  def colours_by_location
    return @location_colours if @location_colours.present?

    @location_colours = {}

    ('A'..'H').each_with_index do |row,row_index|
      (1..12).each_with_index do |col,col_index|
        @location_colours[row + col.to_s] = "colour-#{(col_index * 12) + row_index + 1}"
      end
    end

    @location_colours
  end

  def column(well)
    location = well.try(:location) or return
    column = location.match( /^[A-H](\d[0-2]?)$/ ).try(:[], 1) or return

    "col-#{column}"
  end

  def get_tab_states(presenter)
    tab_states_or_summary(presenter).to_json.html_safe
  end

  # Returns either the tab_states for a logged in user or the labware summary
  # for the current state.
  def tab_states_or_summary(presenter)
    return presenter.authenticated_tab_states if current_user_uuid.present?

    {}.tap { |h| h[presenter.labware.state] = ['labware-summary-button'] }
  end
  private :tab_states_or_summary

  def plates_by_state(plates)
    plates.each_with_object(Hash.new {|h,k| h[k]=[]}) do |plate, plates_by_state|
      plates_by_state[plate.state] << plate
    end
  end

  def well_state_value(container)
    container.state == 'failed' ? 'permanent-failure' : container.state
  end

  def labware_type_and_state 
    "#{@presenter.purpose.name}.#{@presenter.labware.state.downcase}"
  end
end

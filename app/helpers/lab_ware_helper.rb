module LabWareHelper
  def state_change_form(presenter)
    render :partial => 'lab_ware/state_change', :locals => { :presenter => presenter }
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

  cycling_colours(:bait)    { |lab_ware, _|            lab_ware.bait }
  cycling_colours(:tag)     { |lab_ware, _|            lab_ware.pool }
  cycling_colours(:pooling) { |lab_ware, destination|  destination }

  def aliquot_colour(lab_ware)
    case lab_ware.state
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
      edit_admin_plate_path(presenter.plate.uuid),
      :id           => presenter.plate.uuid,
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
    column = well.location.match( /^[A-H](\d[0-2]?)$/ ).try(:[], 1) or return

    "col-#{column}"
  end

  def plates_by_state(plates)
    plates.each_with_object(Hash.new {|h,k| h[k]=[]}) do |plate, plates_by_state|
      plates_by_state[plate.state] << plate
    end
  end

end

module LabWareHelper
  def state_change_form(presenter)
    render :partial => 'lab_ware/state_change', :locals => { :presenter => presenter }
  end

  STANDARD_COLOURS = [ 'green', 'red', 'yellow', 'blue', 'orange' ]

  def self.cycling_colours(name, &block)
    define_method(:"#{name}_colour") do |lab_ware|
      @colours  ||= Hash.new { |h,k| h[k] = STANDARD_COLOURS.dup }
      @rotating ||= Hash.new { |h,k| h[k] = @colours[name].rotate!.first }
      @rotating[block.call(lab_ware)]
    end
  end

  cycling_colours(:bait) { |lab_ware| lab_ware.bait }
  cycling_colours(:pooling) { |lab_ware| lab_ware }

  def aliquot_colour(lab_ware)
    case lab_ware.state
      when "passed"   then "green"
      when "started"  then "orange"
      when "failed"   then "red"
      when "canceled" then "red"
      else "blue"
    end
  end
end

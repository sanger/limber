module LabWareHelper
  def state_change_form(presenter)
    render :partial => 'lab_ware/state_change', :locals => { :presenter => presenter }
  end

  STANDARD_COLOURS = [ 'green', 'red', 'yello', 'blue', 'orange' ]

  def bait_colour(lab_ware)
    @colours                     = STANDARD_COLOURS.dup
    @bait_libraries_to_colours ||= Hash.new { |h,k| h[k] = @colours.rotate!.first }
    @bait_libraries_to_colours[lab_ware.bait]
  end

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

module LabWareHelper
  def state_change_form(presenter)
    render :partial => 'lab_ware/state_change', :locals => { :presenter => presenter }
  end

  def aliquot_colour(lab_ware_item)
    case lab_ware_item.state
      when "passed"   then "green"
      when "started"  then "orange"
      when "failed"   then "red"
      when "canceled" then "red"
      else "blue"
    end
  end
end

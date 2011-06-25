module ApplicationHelper
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

# frozen_string_literal: true

class Labels::TubeLabel < Labels::Base
  def attributes
    { top_line: "#{prioritized_name(labware.name, 10)} #{labware.label.prefix}",
      middle_line: labware.label.text,
      bottom_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: labware.barcode.number,
      barcode: labware.barcode.ean13 }
  end

  private

  # Space on labels is a bit limited. This picks out the most
  # important bits.
  def prioritized_name(str, max_size)
    # Regular expression to match
    return 'Unnamed' if str.blank?
    match = str.match(/([A-Z]{2})(\d+)([[:alpha:]])( )(\w+)(:)(\w+)/)
    return str if match.nil?
    # Sets the priorities position matches in the regular expression to dump into the final string. They will be
    # performed with preference on the most right characters from the original match string
    priorities = [7, 5, 2, 6, 3, 1, 4]

    # Builds the final string by adding the matching string using the previous priorities list
    priorities.each_with_object([]) do |value, cad_list|
      size_to_copy = max_size - cad_list.join('').length
      text_to_copy = match[value]
      cad_list[value] = (text_to_copy[[0, text_to_copy.length - size_to_copy].max, size_to_copy])
      cad_list
    end.join('')
  end
end

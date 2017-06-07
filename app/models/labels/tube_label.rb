# frozen_string_literal: true

class Labels::TubeLabel < Labels::Base
  def attributes
    #we have to remove first two characters from name (normally it is 'DN'),
    #because otherwise we will lose important information about wells
    #if each well takes 3 (not 2) characters, like E10:H10, for example
    { first_line: first_line,
      second_line: second_line,
      third_line: labware.label.text,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: labware.barcode.number,
      barcode: labware.barcode.ean13 }
  end

  private

  def first_line
    labware.name[2..-1] if labware.name.present?
  end

  def second_line
    labware.barcode.number.to_s + ', P' + labware.aliquots.count.to_s
  end

end

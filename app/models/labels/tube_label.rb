# frozen_string_literal: true

class Labels::TubeLabel < Labels::Base
  def attributes
    # we have to remove first two characters from name (normally it is 'DN'),
    # because otherwise we will lose important information about wells
    # if each well takes 3 (not 2) characters, like E10:H10, for example
    { first_line: first_line,
      second_line: second_line,
      third_line: labware.purpose.name,
      fourth_line: date_today,
      round_label_top_line: labware.barcode.prefix,
      round_label_bottom_line: labware.barcode.number,
      barcode: labware.barcode.machine }
  end

  def default_printer_type
    default_printer_type_for(:tube)
  end

  def default_label_template
    default_label_template_for(:tube)
  end

  private

  def first_line
    labware.name[2..-1] if labware.name.present?
  end

  def second_line
    labware.barcode.number.to_s + ', P' + (@options[:pool_size] || labware.aliquots.count).to_s
  end
end

module Pulldown::CommonPlateBehaviour
  def rows
    case self.size
    when 96  then ('A'..'H')
    when 384 then ('A'..'P')
    else          raise RuntimeError, "Unknown plate size #{self.size}"
    end
  end

  def columns
    case self.size
    when 96  then (1..12)
    when 384 then (1..24)
    else          raise RuntimeError, "Unknown plate size #{self.size}"
    end
  end

  def locations_in_rows
    [].tap do |locations|
      self.rows.each do |row|
        self.columns.each do |column|
          locations << "#{row}#{column}"
        end
      end
    end
  end
end

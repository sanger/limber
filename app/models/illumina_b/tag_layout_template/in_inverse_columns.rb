module IlluminaB::TagLayoutTemplate::InInverseColumns
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      (1..12).to_a.reverse.map do |column|
        ('A'..'H').to_a.reverse.map do |row|
          well_location_pool_pair.call(row, column)
        end
      end
    end
  end
  private :group_wells_of_plate
end

module IlluminaB::TagLayoutTemplate::InRows
  def group_wells_of_plate(plate)
    group_wells(plate) do |well_location_pool_pair|
      ('A'..'H').map do |row|
        (1..12).map do |column|
          well_location_pool_pair.call(row, column)
        end
      end
    end
  end
end

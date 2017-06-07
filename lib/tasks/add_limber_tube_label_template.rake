namespace :pmb do
  task add_limber_tube_label_template: :environment do

    def limber_tube_label_template_attributes
      #I make an assumption here that 'Tube' label type exists in PMB
      label_type_id = PMB::LabelType.where(name: 'Tube').first.id
      { "name" => "limber_tube_label_template",
        "label_type_id" => label_type_id,
        "labels_attributes" => [
          { "name" => "main_label",
            "bitmaps_attributes" => [
              { "x_origin" => "0050", "y_origin" => "0130", "field_name" => "fourth_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "02", "rotational_angles" => "11" },
              { "x_origin" => "0080", "y_origin" => "0130", "field_name" => "third_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "03", "rotational_angles" => "11" },
              { "x_origin" => "0110", "y_origin" => "0130", "field_name" => "second_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "02", "rotational_angles" => "11" },
              { "x_origin" => "0140", "y_origin" => "0130", "field_name" => "first_line", "horizontal_magnification" => "05", "vertical_magnification" => "05", "font" => "H", "space_adjustment" => "02", "rotational_angles" => "11" },
              { "x_origin" => "0260", "y_origin" => "0180", "field_name" => "round_label_top_line", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00" },
              { "x_origin" => "0240", "y_origin" => "0210", "field_name" => "round_label_bottom_line", "horizontal_magnification" => "05", "vertical_magnification" => "1", "font" => "G", "space_adjustment" => "00", "rotational_angles" => "00" }
            ],
            "barcodes_attributes" => [
              { "x_origin" => "0050", "y_origin" => "0070", "field_name" => "barcode", "barcode_type" => "5", "one_module_width" => "01", "height" => "0050", "rotational_angle" => nil, "one_cell_width" => nil, "type_of_check_digit" => "2", "bar_height" => nil, "no_of_columns" => nil }
            ]
          }
        ]
      }
    end

    def execute
      limber_tube_label_template = PMB::LabelTemplate.where(name: 'limber_tube_label_template').first
      unless limber_tube_label_template.present?
        limber_tube_label_template = PMB::LabelTemplate.new(limber_tube_label_template_attributes)
        limber_tube_label_template.save ? (puts 'Limber tube label template created') : (puts 'Something went wrong')
      else
        puts 'PMB already has Limber tube label template'
      end
    end

    execute

  end
end
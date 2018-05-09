# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :pmb do
  task register_label_templates: :environment do
    [{ 'name' => 'limber_tube_label_template',
       # I make an assumption here that 'Tube' label type exists in PMB
       'label_type_id' => PMB::LabelType.find(name: 'Tube').first.id,
       'labels_attributes' => [
         { 'name' => 'main_label',
           'bitmaps_attributes' => [
             { 'x_origin' => '0050',
               'y_origin' => '0130',
               'field_name' => 'fourth_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '05',
               'font' => 'H',
               'space_adjustment' => '02',
               'rotational_angles' => '11' },
             { 'x_origin' => '0080',
               'y_origin' => '0130',
               'field_name' => 'third_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '05',
               'font' => 'H',
               'space_adjustment' => '03',
               'rotational_angles' => '11' },
             { 'x_origin' => '0110',
               'y_origin' => '0130',
               'field_name' => 'second_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '05',
               'font' => 'H',
               'space_adjustment' => '02',
               'rotational_angles' => '11' },
             { 'x_origin' => '0140',
               'y_origin' => '0130',
               'field_name' => 'first_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '05',
               'font' => 'H',
               'space_adjustment' => '02',
               'rotational_angles' => '11' },
             { 'x_origin' => '0260',
               'y_origin' => '0180',
               'field_name' => 'round_label_top_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '1',
               'font' => 'G',
               'space_adjustment' => '00',
               'rotational_angles' => '00' },
             { 'x_origin' => '0240',
               'y_origin' => '0210',
               'field_name' => 'round_label_bottom_line',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '1',
               'font' => 'G',
               'space_adjustment' => '00',
               'rotational_angles' => '00' }
           ],
           'barcodes_attributes' => [
             { 'x_origin' => '0050',
               'y_origin' => '0070',
               'field_name' => 'barcode',
               'barcode_type' => '5',
               'one_module_width' => '01',
               'height' => '0050',
               'rotational_angle' => nil,
               'one_cell_width' => nil,
               'type_of_check_digit' => '2',
               'bar_height' => nil,
               'no_of_columns' => nil }
           ] }
       ] },
     { 'name' => 'plate_6mm_double',
       'label_type_id' => PMB::LabelType.find(name: 'plate - 6mm').first.id,
       'labels_attributes' => [
         { 'name' => 'main_label',
           'bitmaps_attributes' => [
             { 'x_origin' => '0010',
               'y_origin' => '0040',
               'field_name' => 'left_text',
               'horizontal_magnification' => '08',
               'vertical_magnification' => '09',
               'font' => 'N',
               'space_adjustment' => '00',
               'rotational_angles' => '00' },
             { 'x_origin' => '0470',
               'y_origin' => '0040',
               'field_name' => 'right_text',
               'horizontal_magnification' => '08',
               'vertical_magnification' => '09',
               'font' => 'N',
               'space_adjustment' => '00',
               'rotational_angles' => '00' }
           ],
           'barcodes_attributes' => [
             { 'x_origin' => '0210',
               'y_origin' => '0000',
               'field_name' => 'barcode',
               'barcode_type' => '5',
               'one_module_width' => '02',
               'height' => '0050',
               'rotational_angle' => nil,
               'one_cell_width' => nil,
               'type_of_check_digit' => '2',
               'bar_height' => nil,
               'no_of_columns' => nil }
           ] },
         { 'name' => 'extra_label',
           'bitmaps_attributes' => [
             { 'x_origin' => '0010',
               'y_origin' => '0035',
               'field_name' => 'left_text',
               'horizontal_magnification' => '05',
               'vertical_magnification' => '06',
               'font' => 'N',
               'space_adjustment' => '00',
               'rotational_angles' => '00' },
             { 'x_origin' => '0150',
               'y_origin' => '0035',
               'field_name' => 'right_text',
               'horizontal_magnification' => '06',
               'vertical_magnification' => '07',
               'font' => 'N',
               'space_adjustment' => '00',
               'rotational_angles' => '00' }
           ] }
       ] }].each do |template|
      template_name = template['name']
      pmb_template = PMB::LabelTemplate.find(name: template_name).first
      if pmb_template.nil?
        ok = PMB::LabelTemplate.new(template).save
        print "Label template: #{template_name} "
        ok ? (puts  'created.') : (puts 'registration failed.')
      else
        puts "Label template: #{template_name}, already registered in PMB"
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength

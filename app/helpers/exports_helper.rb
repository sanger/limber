# frozen_string_literal: true

# Helper methods for the Exports controller
module ExportsHelper
  def each_source_metadata_for_plate(plate)
    plate.wells_in_columns.each do |dest_well|
      dest_well.transfer_requests_as_target.each do |transfer_req|
        # NB. Making assumption here that name field on asset is for a plate well
        # and contains a plate barcode and well location e.g. DN12345678:A1
        src_well = transfer_req.source_asset
        name_array = src_well.name.split(':')
        yield name_array[0], name_array[1], dest_well if name_array.length == 2
      end
    end
  end

  #
  # Returns the total of all aliquots within a well
  #
  # @param well [Sequencescape::Api::V2::Well] The well to count samples in
  #
  # @return [Integer] The total number of aliquots within the well
  #
  def aliquots_count_for(well)
    well.aliquots.count
  end

  def mbrave_tag_name(tag_group_name, tag_position)
    unless Rails.configuration.mbrave.key?(tag_group_name.to_sym)
      raise "Tag group #{tag_group_name} was not configured for mbrave. Please contact PSD."
    end
    Rails.configuration.mbrave[tag_group_name][:tags][tag_position - 1]
  end

  def mbrave_tag_version(tag_group_name)
    unless Rails.configuration.mbrave.key?(tag_group_name.to_sym)
      raise "Tag group #{tag_group_name} was not configured for mbrave. Please contact PSD."
    end
    Rails.configuration.mbrave[tag_group_name][:version]
  end

  def mbrave_tag2_plate_num(tag_group_name)
    unless Rails.configuration.mbrave.key?(tag_group_name.to_sym)
      raise "Tag group #{tag_group_name} was not configured for mbrave. Please contact PSD."
    end
    Rails.configuration.mbrave[tag_group_name][:num_plate]
  end

  # Returns an array of plate number and suffix, and well row and column
  #
  # @param supplier_name
  #
  def mbrave_supplier_name_parts(label)
    # Ignore prefix, capture digits, optional letter, letter and digits
    # sample_SQPU_38225_F_D3 -> [38225, 'F', 'D', 3]
    # sample_SQPU_38225_D3 -> [38225, '', 'D', 3]
    pattern = /(\d+)(?:.*?([A-Z]))?.*?([A-Z])(\d+)/

    match = label.match(pattern)
    match.present? ? [match[1].to_i, match[2] || '', match[3], match[4].to_i] : []
  end

  # Comparison function for mbrave file rows
  def mbrave_row_comparison(row_a, row_b)
    # Generate arrays of 384 plate number, 96 plate sequence and suffix, well row and column
    a_parts = mbrave_supplier_name_parts(row_a[2]).unshift(row_a[4].to_i) # Prepend UMI Plate ID
    b_parts = mbrave_supplier_name_parts(row_b[2]).unshift(row_b[4].to_i)
    a_parts <=> b_parts
  end
end

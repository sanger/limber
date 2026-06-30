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

    Rails.configuration.mbrave[tag_group_name][:tags][tag_position]
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

  # Helper method for scRNA PBMC Pools plate to create rows for the driver files
  # Used in the following exports:
  # - Hamilton LRC PBMC Aliquot to LRC PBMC Pools CSV
  # - Hamilton LRC PBMC Defrost PBS 1ml to LRC PBMC Pools CSV
  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def pbmc_transfer_request_rows(plate, ancestor_plate_list)
    scrna_config = Rails.application.config.scrna_config
    required_number_of_cells_per_sample_in_pool = scrna_config[:required_number_of_cells_per_sample_in_pool]
    maximum_sample_volume = scrna_config[:maximum_sample_volume]
    minimum_sample_volume = scrna_config[:minimum_sample_volume]
    minimum_resuspension_volume = scrna_config[:minimum_resuspension_volume]
    millilitres_to_microlitres = scrna_config[:millilitres_to_microlitres]
    desired_chip_loading_concentration = scrna_config[:desired_chip_loading_concentration]

    ancestor_plates_wells = ancestor_plate_list.each_with_object({}) do |ancestor_plate, hash|
      hash[ancestor_plate.labware_barcode.human] = ancestor_plate.wells.index_by(&:location)
    end

    transfer_request_data = []
    each_source_metadata_for_plate(plate) do |src_barcode, src_location, dest_well|
      src_well = ancestor_plates_wells[src_barcode][src_location]
      cell_count = src_well.latest_total_cell_count
      next if cell_count.nil?

      required_volume = (
          millilitres_to_microlitres * required_number_of_cells_per_sample_in_pool / cell_count.value.to_f
        ).clamp(
          minimum_sample_volume, maximum_sample_volume
        )

      transfer_request_data << [
        src_barcode,
        src_location,
        plate.labware_barcode.human,
        dest_well.location,
        format('%0.1f', required_volume),
        required_number_of_cells_per_sample_in_pool
      ]
    end

    samples_by_dest_well = transfer_request_data.group_by { |tr| tr[3] }

    rows_array = transfer_request_data.map do |data|
      samples_in_pool = samples_by_dest_well[data[3]].count
      required_number_of_cells_per_sample_in_pool = data[5]
      resuspension_volume = [
        LabwareCreators::DonorPoolingCalculator.calculate_total_cells_in_300ul(samples_in_pool) /
          desired_chip_loading_concentration,
        minimum_resuspension_volume
      ].max
      data[5] = format('%0.1f', resuspension_volume)
      data
    end
    rows_array.sort_by { |a| [a[0], WellHelpers.well_coordinate(a[1])] }
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
end

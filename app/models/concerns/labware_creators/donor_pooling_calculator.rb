# frozen_string_literal: true

# rubocop:todo Metrics/ModuleLength
# This module contains algorithms to allocate source wells into a target number of pools.
module LabwareCreators::DonorPoolingCalculator
  extend ActiveSupport::Concern

  VALID_POOL_SIZE_RANGE = Rails.application.config.scrna_config[:valid_pool_size_range]
  # Enum to aid allowance band calculations
  ALLOWANCE_BANDS = {
    two_pools_two_counts: '2 pool attempts, 2 counts',
    two_pools_one_count: '2 pool attempts, 1 count',
    one_pool_two_counts: '1 pool attempt, 2 counts',
    one_pool_one_count: '1 pool attempt, 1 count'
  }.freeze

  # Splits wells into groups by study and project, because:
  # a) no pool should contain samples from more than one study or project,
  #    to limit the risk of data leakage between studies, and
  # b) the requested number of pools is specified at the study/project level,
  #    because different study/project groups could be from different customers.
  #
  # Wells are grouped based on the study and project of the first aliquot in each well
  # (only one aliquot is expected per well). Returns an array of groups, where each group
  # is an array of wells with the same study and project.
  #
  # If the input group is [w1, w2, w3, w4, w5, w6, w7, w8, w9]
  # where w1, w2, w3, w4, w5, w6, w7, w8, and w9 are wells with (study_id, project_id),
  #
  # w1(1,1)
  # w2(1,2)
  # w3(1,3)
  # w4(1,1)
  # w5(1,2)
  # w6(1,3)
  # w7(1,1)
  # w8(2,1)
  # w9(2,2)
  #
  # the result will be:
  # [[w1, w4, w7], [w2, w5], [w3, w6], [w8], [w9]]
  #
  # @param group [Array<Well>] The group of wells to be split.
  # @return [Array<Array<Well>>] An array of well groups.
  def split_single_group_by_study_and_project(group)
    group.group_by { |well| [well.aliquots.first.study.id, well.aliquots.first.project.id] }.values
  end

  def validate_pool_sizes!(pools)
    if pools.any? { |pool| !VALID_POOL_SIZE_RANGE.cover?(pool.size) }
      raise 'Invalid distribution: Each pool must have ' \
            "between #{VALID_POOL_SIZE_RANGE.min} and #{VALID_POOL_SIZE_RANGE.max} wells."
    end

    pool_sizes = pools.map(&:size)
    return unless pool_sizes.max - pool_sizes.min > 1

    raise 'Invalid distribution: Pool sizes differ by more than one.'
  end

  # rubocop:todo Metrics/AbcSize
  # Allocates wells to pools. The wells will have grouped by study and project, and now
  # they will be grouped by unique donor_ids. The wells will be distributed sequentially
  # to the pools, ensuring that each pool has between 5 and 25 wells.
  #
  # If the number of wells is 96 and the number of pools is 8, then
  # each pool will have 12 wells
  # [[12], [12], [12], [12], [12], [12], [12], [12]]
  #
  #
  # If the number of wells is 96 and the number of pools is 7, then
  # the first 5 pools will have 14 wells and the last 2 pools will have 13 wells
  # [[14], [14], [14], [14], [14], [13], [13]]
  #
  # If the number of wells is 24 and the number of pools is 5, then
  # an error will be raised because each pool must have at least 5 wells
  #
  # @param wells [Array<Well>] The wells to be allocated to pools.
  # @param number_of_pools [Integer] The number of pools to distribute the wells into.
  # @return [Array<Array<Well>>] An array of pools, between 1 and 8, each containing between 5 and 25 wells.
  def allocate_wells_to_pools(wells, number_of_pools)
    pools = Array.new(number_of_pools) { [] }
    used_donor_ids = Array.new(number_of_pools) { [] }

    # Calculate ideal pool sizes based on the number of wells and pools
    ideal_pool_size, remainder = wells.size.divmod(number_of_pools)

    # If there's a remainder, some pools will have one more well than others
    pool_sizes = Array.new(number_of_pools, ideal_pool_size)
    remainder.times { |i| pool_sizes[i] += 1 }

    wells = reorder_wells_by_donor_id(wells)

    # Assign wells to pools
    # Loop through the wells, and then the pools, and break out when we successfully assign a well
    #
    wells.each do |well|
      assigned = false
      donor_id = well.aliquots.first.sample.sample_metadata.donor_id

      pools.each_with_index do |pool, pool_index|
        # if this pool is full, try the next pool
        next if pool.size >= pool_sizes[pool_index]

        # this pool already contains a sample with this donor_id, try the next pool
        next if used_donor_ids[pool_index].include?(donor_id)

        # add the well to the pool, and skip to the next well to allocate
        pool << well
        used_donor_ids[pool_index] << donor_id
        assigned = true
        break
      end

      next if assigned

      raise 'Cannot find a pool to assign the well to.'
    end

    validate_pool_sizes!(pools)
    validate_unique_donor_ids!(pools)
    pools
  end
  # rubocop:enable Metrics/AbcSize

  # Reorder wells before splitting them into pools,
  # so that the largest groups that share the same donor_id will be allocated to pools first.
  # This prevents us from getting in a situation where the first pools fill up, and then we don't have enough pools
  # left to split up a large group of wells that share the same donor_id.
  # See test 'when the groups of donor ids are not ordered largest to smallest' in donor_pooling_calculator_spec.rb
  def reorder_wells_by_donor_id(wells)
    # { donor_id_1 => [wells], donor_id_2 => [wells], ... }
    donor_id_to_wells = wells.group_by { |well| well.aliquots.first.sample.sample_metadata.donor_id }

    # { donor_id_1 => [wells], donor_id_2 => [wells], ... } sorted by number of wells in each group
    donor_id_to_wells = stable_sort_hash_by_values_size_desc(donor_id_to_wells)

    # [well, well, ...] flattened back into a reordered array of wells
    donor_id_to_wells.pluck(1).flatten
  end

  # 'Stable sort' means the original order is maintained wherever possible.
  # Should make pooling results more intuitive.
  def stable_sort_hash_by_values_size_desc(the_hash)
    the_hash.sort_by.with_index { |elem, idx| [-elem[1].size, idx] }
  end

  # Ensure that each pool contains unique donor IDs.
  #
  # @param pools [Array<Array<Well>>] The current pools.
  #
  # @return [void]
  def validate_unique_donor_ids!(pools)
    pools.each_with_index do |pool, index|
      donor_ids = pool.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }
      next unless donor_ids.uniq.size != donor_ids.size

      raise "Pool #{index + 1} contains duplicate donor IDs: #{donor_ids.tally.select { |_id, count| count > 1 }.keys}"
    end
  end

  # This method checks the pool against the allowance band and adjusts the number of
  # cells per chip well value if needed.
  # It then stores the number of cells per chip well as metadata on the destination well.
  #
  # @param pool [Array<SourceWell>] an array of source wells from the v2 API
  # @param dest_plate [Object] the destination plate
  # @param dest_well_location [String] the location of the destination well
  def check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
    # count sum of samples in all source wells in the pool (typically will be one sample per source well)
    # for each source well, number of samples = well.aliquots.size
    count_of_samples_in_pool = pool.sum { |source_well| source_well.aliquots.size }

    # fetch number of cells per chip well from the request metadata of the first aliquot in the first source well
    number_of_cells_per_chip_well = number_of_cells_per_chip_well_from_request(pool)

    # fetch allowance band from the request metadata of the first aliquot in the first source well
    allowance_band = allowance_band_from_request(pool)

    # only consider adjusting the number of cells per chip well if the count of samples in the pool is between the min
    # and max values from the allowance table
    if count_of_samples_in_pool.between?(allowance_table_min_num_samples, allowance_table_max_num_samples)
      # check and adjust number of cells per chip well if needed
      number_of_cells_per_chip_well =
        adjust_number_of_cells_per_chip_well(count_of_samples_in_pool, number_of_cells_per_chip_well, allowance_band)
    end

    # store number of cells per chip well in destination pool well poly metadata
    dest_well = dest_plate.well_at_location(dest_well_location)

    create_new_well_metadata(
      Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key],
      number_of_cells_per_chip_well,
      dest_well
    )
  end

  # This method calculates the total cells in 300ul for a given pool of samples.
  # It uses the configuration values from the scrna_config to determine the required
  # number of cells per sample in the pool and the wastage factor.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @return [Float] the total cells in 300ul
  def self.calculate_total_cells_in_300ul(count_of_samples_in_pool)
    scrna_config = Rails.application.config.scrna_config

    (count_of_samples_in_pool * scrna_config[:required_number_of_cells_per_sample_in_pool]) *
      scrna_config[:wastage_factor].call(count_of_samples_in_pool)
  end

  private

  # This method retrieves the number of cells per chip well from the request metadata
  # of the first aliquot in the first source well of the provided pool.
  # If the cells per chip well value is not present, it raises a StandardError.
  #
  # @param pool [Array<SourceWell>] an array of source wells from the v2 API
  # @return [Integer] the number of cells per chip well
  # @raise [StandardError] if the cells per chip well value is not found in the request metadata
  def number_of_cells_per_chip_well_from_request(pool)
    # pool is an array of v2 api source wells, fetch the first well from the pool
    source_well = pool.first

    # fetch request metadata for number of cells per chip well from first aliquot in the source well
    # (it should be the same value for all the aliquots in all the source wells in the pool)
    cells_per_chip_well = source_well&.aliquots&.first&.request&.request_metadata&.cells_per_chip_well

    if cells_per_chip_well.blank?
      raise StandardError,
            "No request found for source well at #{source_well.location}, cannot fetch cells per chip " \
            'well metadata for allowance band calculations'
    end

    cells_per_chip_well
  end

  # This method retrieves the allowance_band from the request metadata
  # of the first aliquot in the first source well of the provided pool.
  # If the allowance_band is not present, it raises a StandardError.
  #
  # @param pool [Array<SourceWell>] an array of source wells from the v2 API
  # @return [String] the allowance band
  # @raise [StandardError] if the allowance_band value is not found in the request metadata
  def allowance_band_from_request(pool)
    # pool is an array of v2 api source wells, fetch the first well from the pool
    source_well = pool.first

    # fetch request metadata for number of cells per chip well from first aliquot in the source well
    # (it should be the same value for all the aliquots in all the source wells in the pool)
    allowance_band = source_well&.aliquots&.first&.request&.request_metadata&.allowance_band

    if allowance_band.blank?
      raise StandardError,
            "No request found for source well at #{source_well.location}, cannot fetch allowance band " \
            'well metadata for allowance band calculations'
    end

    allowance_band
  end

  def allowance_table_min_num_samples
    Rails.application.config.scrna_config[:allowance_table][ALLOWANCE_BANDS[:two_pools_two_counts]].keys.min
  end

  def allowance_table_max_num_samples
    Rails.application.config.scrna_config[:allowance_table][ALLOWANCE_BANDS[:two_pools_two_counts]].keys.max
  end

  # This method adjusts the number of cells per chip well based on the count of samples in the pool.
  # If the final suspension volume is greater than or equal to the allowance band, the existing value is retained.
  # Otherwise, the number of cells per chip well is adjusted according to the allowance band table.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @param number_of_cells_per_chip_well [Integer] the initial number of cells per chip well
  # @return [Integer] the adjusted number of cells per chip well
  def adjust_number_of_cells_per_chip_well(count_of_samples_in_pool, number_of_cells_per_chip_well, allowance_band)
    # calculate total cells in 300ul for the pool
    total_cells_in_300ul = LabwareCreators::DonorPoolingCalculator.calculate_total_cells_in_300ul(count_of_samples_in_pool)

    # calculate final suspension volume
    final_suspension_volume =
      total_cells_in_300ul / Rails.application.config.scrna_config[:desired_chip_loading_concentration]

    # calculate chip loading volume
    chip_loading_volume = calculate_chip_loading_volume(number_of_cells_per_chip_well)

    # calculate volume_needed
    volume_needed = calculate_allowance(chip_loading_volume, allowance_band)

    # do not adjust existing value if we have enough volume
    return number_of_cells_per_chip_well if final_suspension_volume >= volume_needed

    # we need to adjust the number of cells per chip well according to the number of samples
    # if an appropriate value is not found in the allowance table, raise an error
    Rails.application.config.scrna_config[:allowance_table][allowance_band][count_of_samples_in_pool] ||
      raise(
        StandardError,
        "No allowance value found for allowance band #{allowance_band} and sample count " \
        "#{count_of_samples_in_pool}"
      )
  end

  # This method calculates the chip loading volume for a given pool of samples.
  # It retrieves the number of cells per chip well from the request metadata
  # and uses the desired chip loading concentration from the scrna_config.
  #
  # @param num_cells_per_chip_well [Integer] the number of cells per chip well from the request metadata
  # @return [Float] the chip loading volume
  def calculate_chip_loading_volume(num_cells_per_chip_well)
    chip_loading_conc = Rails.application.config.scrna_config[:desired_chip_loading_concentration]

    num_cells_per_chip_well / chip_loading_conc
  end

  # This method calculates the allowance volume for a given chip loading volume and allowance band.
  # It uses configuration values from the scrna_config for the desired
  # number of runs, the volume taken for cell counting, and the wastage volume.
  #
  # @param chip_loading_volume [Float] the chip loading volume
  # @return [Float] the volume of material required to do the number of runs and cell counts specified
  #                 in the allowance band
  def calculate_allowance(chip_loading_volume, allowance_band) # rubocop:disable Metrics/AbcSize
    scrna_config = Rails.application.config.scrna_config

    case allowance_band
    when ALLOWANCE_BANDS[:two_pools_two_counts]
      (chip_loading_volume * 2) + (2 * scrna_config[:volume_taken_for_cell_counting]) + scrna_config[:wastage_volume]
    when ALLOWANCE_BANDS[:two_pools_one_count]
      (chip_loading_volume * 2) + scrna_config[:volume_taken_for_cell_counting] + scrna_config[:wastage_volume]
    when ALLOWANCE_BANDS[:one_pool_two_counts]
      chip_loading_volume + (2 * scrna_config[:volume_taken_for_cell_counting]) + scrna_config[:wastage_volume]
    when ALLOWANCE_BANDS[:one_pool_one_count]
      chip_loading_volume + scrna_config[:volume_taken_for_cell_counting] + scrna_config[:wastage_volume]
    end
  end

  # This method creates a new well metadata entry for a given destination well.
  # It initializes a new PolyMetadatum object with the provided metadata key and value,
  # associates it with the destination well, and attempts to save it.
  # If the save operation fails, it raises a StandardError with a descriptive message.
  #
  # @param metadata_key [String] the key for the metadata
  # @param metadata_value [String] the value for the metadata
  # @param dest_well [Object] the destination well to associate the metadata with
  # @raise [StandardError] if the metadata entry fails to save
  def create_new_well_metadata(metadata_key, metadata_value, dest_well)
    pm_v2 = Sequencescape::Api::V2::PolyMetadatum.new(key: metadata_key, value: metadata_value)
    pm_v2.relationships.metadatable = dest_well

    return if pm_v2.save

    raise StandardError,
          "New metadata for request (key: #{metadata_key}, value: #{metadata_value}) " \
          "did not save on destination well at location #{dest_well.location}"
  end
end
# rubocop:enable Metrics/ModuleLength

# frozen_string_literal: true
# rubocop:disable Metrics/ModuleLength

# This module contains algorithms to allocate source wells into a target number of pools.
module LabwareCreators::DonorPoolingCalculator
  extend ActiveSupport::Concern

  VALID_POOL_SIZE_RANGE = (5..25)

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

  # Recursive function to assign wells to pools
  # Assigns a well to a pool based on the provided arguments.
  #
  # @param [Hash] args The arguments for assigning the well to a pool.
  # @option args [Object] :well The well to be assigned.
  # @option args [Array] :pools The array of pools.
  # @option args [Array] :used_donor_ids The array of used donor IDs.
  # @option args [Integer] :pool_index The index of the current pool.
  # @option args [Integer] :number_of_pools The total number of pools.
  # @option args [Integer] :depth The depth of the current operation.
  #
  # @return [void]
  #
  def assign_well_to_pool(args)
    well, pools, used_donor_ids, pool_index, number_of_pools, depth =
      args.values_at(:well, :pools, :used_donor_ids, :pool_index, :number_of_pools, :depth, :conflict_depth)

    donor_id = well.aliquots.first.sample.sample_metadata.donor_id

    if donor_already_used?(donor_id, used_donor_ids, pool_index)
      handle_conflict_donor_ids(donor_id, args, depth, number_of_pools, pool_index)
    else
      add_to_pool(donor_id, used_donor_ids, pool_index, pools, well)
    end
  end

  def donor_already_used?(donor_id, used_donor_ids, pool_index)
    used_donor_ids[pool_index].include?(donor_id)
  end

  def handle_conflict_donor_ids(donor_id, args, depth, number_of_pools, pool_index)
    increment_depth!(args)
    check_all_pools_visited!(depth, number_of_pools, donor_id)
    check_all_pools_visited!(args[:conflict_depth], number_of_pools, donor_id)
    reassign_to_next_pool(args, pool_index, number_of_pools)
  end

  def increment_depth!(args)
    args[:depth] += 1
  end

  def check_all_pools_visited!(depth, number_of_pools, donor_id)
    raise "Unable to allocate well with donor ID #{donor_id}. All pools contain this donor." if depth == number_of_pools
  end

  # Reassigns the given well to the next pool in a round-robin fashion.
  #
  # @param args [Hash] The arguments hash containing details about the well.
  # @param pool_index [Integer] The current index of the pool.
  # @param number_of_pools [Integer] The total number of pools.
  #
  # @return [void]
  def reassign_to_next_pool(args, pool_index, number_of_pools)
    args[:pool_index] = (pool_index + 1) % number_of_pools
    assign_well_to_pool(args.merge(conflict_depth: args[:conflict_depth] + 1))
  end

  # Adds a donor to a specified pool and associates it with a well.
  #
  # @param donor_id [Integer] the ID of the donor to be added to the pool
  # @param used_donor_ids [Array<Array<Integer>>] a nested array where each sub-array contains donor IDs
  #   for a specific pool
  # @param pool_index [Integer] the index of the pool to which the donor should be added
  # @param pools [Array<Array<Well>>] a nested array where each sub-array contains wells for a specific pool
  # @param well [Well] the well to be associated with the donor in the specified pool
  # @return [void]
  def add_to_pool(donor_id, used_donor_ids, pool_index, pools, well)
    used_donor_ids[pool_index] << donor_id
    pools[pool_index] << well
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

  # rubocop:disable Metrics/AbcSize
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

    depth = 0

    # Calculate ideal pool sizes based on the number of wells and pools
    ideal_pool_size, remainder = wells.size.divmod(number_of_pools)

    # If there's a remainder, some pools will have one more well than others
    pool_sizes = Array.new(number_of_pools, ideal_pool_size)
    remainder.times { |i| pool_sizes[i] += 1 }

    # Assign wells to pools
    well_index = 0
    pools.each_with_index do |pool, pool_index|
      # Determine how many wells this pool should get based on pool_sizes
      pool_size = pool_sizes[pool_index]
      conflict_depth = 0

      while pool.size < pool_size
        well = wells[well_index]
        assign_well_to_pool({ well:, pools:, used_donor_ids:, pool_index:, number_of_pools:, depth:, conflict_depth: })
        well_index += 1
      end
    end

    validate_pool_sizes!(pools)
    validate_unique_donor_ids!(pools)
    pools
  end

  # rubocop:enable Metrics/AbcSize

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

  # This method checks the pool for full allowance and adjusts the number of
  # cells per chip well value if needed.
  # It then stores the number of cells per chip well as metadata on the destination well.
  #
  # @param pool [Array<SourceWell>] an array of source wells from the v2 API
  # @param dest_plate [Object] the destination plate
  # @param dest_well_location [String] the location of the destination well
  def check_pool_for_full_allowance(pool, dest_plate, dest_well_location)
    # count sum of samples in all source wells in the pool (typically will be one sample per source well)
    # for each source well, number of samples = well.aliquots.size
    count_of_samples_in_pool = pool.sum { |source_well| source_well.aliquots.size }

    # fetch number of cells per chip well from the request metadata of the first aliquot in the first source well
    number_of_cells_per_chip_well = number_of_cells_per_chip_well_from_request(pool)

    # only consider adjusting the number of cells per chip well if the count of samples in the pool is between 5 and 8
    if count_of_samples_in_pool >= 5 && count_of_samples_in_pool <= 8
      # check and adjust number of cells per chip well if needed
      number_of_cells_per_chip_well =
        adjust_number_of_cells_per_chip_well(count_of_samples_in_pool, number_of_cells_per_chip_well)
    end

    # store number of cells per chip well in destination pool well poly metadata
    dest_well = dest_plate.well_at_location(dest_well_location)

    create_new_well_metadata(
      Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key],
      number_of_cells_per_chip_well,
      dest_well
    )
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
              'well metadata for full allowance calculations'
    end

    cells_per_chip_well
  end

  # This method adjusts the number of cells per chip well based on the count of samples in the pool.
  # If the final suspension volume is greater than or equal to the full allowance, the existing value is retained.
  # Otherwise, the number of cells per chip well is adjusted according to the full allowance table.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @param number_of_cells_per_chip_well [Integer] the initial number of cells per chip well
  # @return [Integer] the adjusted number of cells per chip well
  def adjust_number_of_cells_per_chip_well(count_of_samples_in_pool, number_of_cells_per_chip_well)
    # calculate total cells in 300ul for the pool
    total_cells_in_300ul = calculate_total_cells_in_300ul(count_of_samples_in_pool)

    # calculate final suspension volume
    final_suspension_volume =
      total_cells_in_300ul / Rails.application.config.scrna_config[:desired_chip_loading_concentration]

    # calculate chip loading volume
    chip_loading_volume = calculate_chip_loading_volume(number_of_cells_per_chip_well)

    # calculate full allowance
    full_allowance = calculate_full_allowance(chip_loading_volume)

    # do not adjust existing value if we have enough volume
    return number_of_cells_per_chip_well if final_suspension_volume >= full_allowance

    # we need to adjust the number of cells per chip well according to the number of samples
    Rails.application.config.scrna_config[:full_allowance_table][count_of_samples_in_pool]
  end

  # This method calculates the total cells in 300ul for a given pool of samples.
  # It uses the configuration values from the scrna_config to determine the required
  # number of cells per sample in the pool and the wastage factor.
  #
  # @param count_of_samples_in_pool [Integer] the number of samples in the pool
  # @return [Float] the total cells in 300ul
  def calculate_total_cells_in_300ul(count_of_samples_in_pool)
    scrna_config = Rails.application.config.scrna_config

    (count_of_samples_in_pool * scrna_config[:required_number_of_cells_per_sample_in_pool]) *
      scrna_config[:wastage_factor]
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

  # This method calculates the full allowance volume for a given chip loading volume.
  # It uses configuration values from the scrna_config for the desired
  # number of runs, the volume taken for cell counting, and the wastage volume.
  #
  # @param chip_loading_volume [Float] the chip loading volume
  # @return [Float] the full allowance volume
  def calculate_full_allowance(chip_loading_volume)
    scrna_config = Rails.application.config.scrna_config

    (chip_loading_volume * scrna_config[:desired_number_of_runs]) +
      (scrna_config[:desired_number_of_runs] * scrna_config[:volume_taken_for_cell_counting]) +
      scrna_config[:wastage_volume]
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

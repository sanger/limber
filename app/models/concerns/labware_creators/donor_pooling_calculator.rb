# frozen_string_literal: true
# rubocop:disable Metrics/ModuleLength

# This module contains algorithms to allocate source wells into a target number of pools.
module LabwareCreators::DonorPoolingCalculator
  extend ActiveSupport::Concern

  VALID_POOL_SIZE_RANGE = (5..25)

  # Splits wells into groups by study and project. Wells are grouped based on the
  # study and project of the first aliquot in each well (only one aliquot is
  # expected per well). Returns an array of groups, where each group is an array
  # of wells with the same study and project.
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

  # Splits groups ensuring unique donor_ids within each group. Iterates over
  # each group, creating subgroups with wells from a unique donor. The first
  # occurrences of unique donor_ids are grouped, then the second occurrences,
  # and so on. This prevents combining samples with the same donor_id. The
  # result is flattened to a single array of subgroups.
  #
  # If the input groups are [[w1, w2, w3, w4], [w5, w6, w7], [w8, w9]]
  # where w1, w2, w3, w4, w5, w6, w7, w8, and w9 are wells with (donor_id),
  #
  # w1(1)
  # w2(2)
  # w3(3)
  # w4(1)
  # w5(4)
  # w6(4)
  # w7(5)
  # w8(6)
  # w9(7)
  #
  # the result will be:
  # [[w1, w2, w3], [w4], [w5, w7], [w6], [w8, w9]]
  #
  # Note that the input groups are not mixed. donor_ids are unique within each
  # result subgroup.
  #
  # @param groups [Array<Array<Well>>] Array of well groups to be split.
  # @return [Array<Array<Well>>] Array of subgroups split by donor ID.
  def split_groups_by_unique_donor_ids(groups)
    groups.flat_map { |group| split_single_group_by_unique_donor_ids(group) }
  end

  # Splits a single group of wells by donor_ids. This method is used by the
  # 'split_groups_by_unique_donor_ids' method. It iteratively segregates wells with
  # the first encountered instance of each unique donor_id into a separate
  # subgroup. This process continues until there are no wells left in the
  # original group. The result is a collection of subgroups, each containing
  # wells from distinct donors.
  #
  # If the input group is [w1, w2, w3, w4, w5, w6, w7, w8, w9]
  # where w1, w2, w3, w4, w5, w6, w7, w8, and w9 are wells with (donor_id),
  #
  # w1(1)
  # w2(2)
  # w3(3)
  # w4(1)
  # w5(2)
  # w6(4)
  # w7(5)
  # w8(5)
  # w9(5)
  #
  # the result will be:
  # [[w1, w2, w3, w6, w7], [w4, w5, w8], [w9]]
  #
  # @param group [Array<Well>] The group of wells to split.
  # @return [Array<Array<Well>>] An array of subgroups, each containing wells
  #   from different donors.
  def split_single_group_by_unique_donor_ids(group)
    group = group.dup
    output = []
    wells_moved = 0
    wells_total = group.size
    while wells_moved < wells_total
      subgroup = []
      unique_donor_ids(group).each do |donor_id|
        wells_moved += 1
        index = group.index { |well| well.aliquots.first.sample.sample_metadata.donor_id == donor_id }
        subgroup << group.delete_at(index)
      end
      output << subgroup
    end
    output
  end

  # Returns the unique donor_ids from a group of wells. Used by the
  # 'split_single_group_by_unique_donor_ids' method.
  #
  # If the input group is [w1, w2, w3, w4, w5, w6, w7, w8, w9]
  # where w1, w2, w3, w4, w5, w6, w7, w8, and w9 are wells with (donor_id),
  #
  # w1(1)
  # w2(2)
  # w3(3)
  # w4(1)
  # w5(2)
  # w6(4)
  # w7(5)
  # w8(5)
  # w9(5)
  #
  # the result will be:
  # [1, 2, 3, 4, 5]
  #
  # @param group [Array<Well>] The group of wells from which to retrieve donor_ids.
  # @return [Array<String>] An array of unique donor_ids.
  def unique_donor_ids(group)
    group.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq
  end

  # Validates the number of pools based on the given wells.
  #
  # @param wells [Array] an array representing the wells.
  # @param number_of_pools [Integer] the number of pools to distribute the wells into.
  # @raise [RuntimeError] if the total number of wells cannot be distributed into the specified number of pools
  #   such that the difference in the number of wells per pool is at most 1.
  def validate_number_of_pools(wells, number_of_pools)
    total_wells = wells.size

    return unless total_wells < number_of_pools || total_wells > number_of_pools * ((total_wells / number_of_pools) + 1)
    raise "Cannot distribute #{total_wells} wells into #{number_of_pools} pools such that the difference is at most 1."
  end

  def handle_non_unique_donor_id(depth, number_of_pools, donor_id)
    return unless depth == number_of_pools
    raise "Unable to allocate well with donor ID #{donor_id}. All pools contain this donor."
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
      args.values_at(:well, :pools, :used_donor_ids, :pool_index, :number_of_pools, :depth)

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
    assign_well_to_pool(args)
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
  #
  def allocate_wells_to_pools(wells, number_of_pools)
    pools = Array.new(number_of_pools) { [] }
    used_donor_ids = Array.new(number_of_pools) { [] }

    validate_number_of_pools(wells, number_of_pools)
    depth = 0

    # Assign wells to pools
    wells.each_with_index do |well, index|
      # Start assigning wells starting from the pool corresponding to the well's index
      assign_well_to_pool(
        {
          well: well,
          pools: pools,
          used_donor_ids: used_donor_ids,
          pool_index: index % number_of_pools,
          number_of_pools: number_of_pools,
          depth: depth
        }
      )
    end

    if pools.any? { |pool| !VALID_POOL_SIZE_RANGE.cover?(pool.size) }
      raise 'Invalid distribution: Each pool must have ' \
              "between #{VALID_POOL_SIZE_RANGE.min} and #{VALID_POOL_SIZE_RANGE.max} wells."
    end
    pools
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
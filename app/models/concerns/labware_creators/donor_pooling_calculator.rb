# frozen_string_literal: true

# This module contains algorithms to allocate source wells into a target number of pools.
module LabwareCreators::DonorPoolingCalculator
  extend ActiveSupport::Concern

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

  # Distributes samples across pools based on group sizes and the number of
  # pools. It allocates a proportion of the number of pools to each group based
  # on their size first and then splits each group evenly across the allocated
  # number of pools.
  #
  # If the number of pools is 6 and the input groups are
  # [[1, 2, 3], [4, 5], [6, 7, 8, 9]] where the numbers denote wells,
  #
  # the result will be:
  # [[6, 7], [8], [9], [1, 2], [3], [4, 5]]
  #
  # @param groups [Array<Array<Well>>] Array of well groups to be distributed.
  #
  # @return [Array<Array<Well>>] Array of distributed groups.
  def distribute_groups_across_pools(groups, number_of_pools)
    allocate_number_of_pools(groups, number_of_pools)
      .flat_map { |group, number_of_slices| even_slicing(group, number_of_slices) }
  end

  # Allocates a proportion of the number of pools to each group.
  #
  # @param groups [Array<Array<Well>>] Array of well groups to be distributed.
  #
  # @return [Hash<Array<Well>, Integer>] Hash of groups and the number of pools allocated to each group.
  def allocate_number_of_pools(groups, number_of_pools)
    total_size = groups.sum(&:size)
    allocations = {}
    allocated_pools = 0

    # Calculate initial allocations based on proportion of total size
    groups.each do |group|
      proportion = group.size.to_f / total_size
      allocation = (number_of_pools * proportion).floor
      allocations[group] = allocation
      allocated_pools += allocation
    end

    # Distribute any remaining pools starting from the largest group
    remainder = number_of_pools - allocated_pools
    groups.sort_by! { |group| -group.size }
    groups.each do |group|
      break if remainder <= 0
      allocations[group] += 1
      remainder -= 1
    end

    allocations
  end

  # Splits a group of wells into a specified number of slices.
  #
  # @params group [Array<Well>] The group of wells to be split.
  # @params number_of_slices [Integer] The number of slices to split the group into.
  #
  # @return [Array<Array<Well>>] An array of slicesx
  def even_slicing(group, number_of_slices)
    total_elements = group.length
    base_size = total_elements / number_of_slices
    remainder = total_elements % number_of_slices
    slices = []
    start_index = 0

    number_of_slices.times do |i|
      size = base_size + (i < remainder ? 1 : 0)
      slices << group[start_index, size]
      start_index += size
    end

    slices
  end



end

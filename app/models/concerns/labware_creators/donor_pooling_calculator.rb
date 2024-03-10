# frozen_string_literal: true

# This module contains algorithms to allocate source wells into a target number of pools.
module LabwareCreators::DonorPoolingCalculator
  extend ActiveSupport::Concern

  # Splits wells into groups by study and project. Wells are grouped based on the
  # study and project of the first aliquot in each well (only one aliquot is
  # expected per well). Returns an array of groups, where each group is an array
  # of wells with the same study and project.
  #
  # @param group [Array<Well>] The group of wells to be split.
  # @return [Array<Array<Well>>] An array of well groups.
  def split_single_group_by_study_and_project(group)
    group.group_by { |well| [well.aliquots.first.study.id, well.aliquots.first.project.id] }.values
  end

  # Splits groups ensuring unique donor_ids within each group. Iterates over
  # each group, creating subgroups with wells from a unique donor. The first
  # occurrences of unique donor_ids are grouped, then the second occurrences,
  # and so on. This prevents combining samples with the same donor_id.
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
  # @param group [Array<Well>] The group of wells to split.
  # @return [Array<Array<Well>>] An array of subgroups, each containing wells
  #   from different donors.
  def split_single_group_by_unique_donor_ids(group)
    group = group.dup
    output = []
    while group.any?
      subgroup = []
      unique_donor_ids(group).each do |donor_id|
        index = group.index { |well| well.aliquots.first.sample.sample_metadata.donor_id == donor_id }
        subgroup << group.delete_at(index) unless index.nil?
      end
      output << subgroup
    end
    output
  end

  # Returns the unique donor_ids from a group of wells. Used by the
  # 'split_single_group_by_unique_donor_ids' method.
  #
  # @param group [Array<Well>] The group of wells from which to retrieve donor_ids.
  # @return [Array<String>] An array of unique donor_ids.
  def unique_donor_ids(group)
    group.map { |well| well.aliquots.first.sample.sample_metadata.donor_id }.uniq
  end

  # Distributes samples across pools based on group sizes. It sorts the groups
  # by size and splits the largest group into two until the number of groups
  # equals the number of pools or until all groups have a size of 1. The input
  # groups are the result of applying conditions, hence they cannot be mixed.
  #
  # @param groups [Array<Array<Well>>] Array of well groups to be distributed.
  # @return [Array<Array<Well>>] Array of distributed groups.
  def distribute_groups_across_pools(groups, number_of_pools)
    groups = groups.dup
    groups.sort_by!(&:size)
    while groups.any? && groups.last.size > 1 && groups.size < number_of_pools
      splits = (largest = groups.pop).each_slice((largest.size / 2.0).ceil).to_a
      groups.concat(splits).sort_by!(&:size)
    end
    groups
  end
end

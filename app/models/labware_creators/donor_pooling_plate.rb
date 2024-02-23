# frozen_string_literal: true

module LabwareCreators
  # This labware creator receives barcodes for a configured number of source
  # plates from the user. It pools samples from the passed wells into a
  # destination plate. It's used for scRNA Donor Pooling to create 'LRC PBMC
  # Pools' plates from 'LRC PBMC Defrost PBS' plates.
  #
  # The creator imposes restrictions:
  # - It doesn't allow combining samples from different studies or projects.
  # - It doesn't allow samples with the same donor_id in the same pool.
  #
  # The number of pools is determined by a lookup table based on sample count.
  class DonorPoolingPlate < Base
    include LabwareCreators::CustomPage
    include SupportParent::PlateOnly

    # The name of the template that will be used for rendering the barcode
    # input page.
    self.page = 'donor_pooling_plate'

    # Add the :barcodes attribute to the list of attributes for this class.
    # The :barcodes attribute is initialized as an empty array.
    self.attributes += [{ barcodes: [] }]

    # Define related objects to be included when retrieving source plates from
    # Sequencescape API V2.
    SOURCE_PLATE_INCLUDES = %w[
      purpose
      wells.aliquots.study
      wells.aliquots.project
      wells.aliquots.request
      wells.aliquots.sample.sample_metadata
      wells.requests_as_source
    ].freeze

    # The default number of pools to be created if the count is not found in
    # the lookup table. For scRNA Donor Pooling, until a new CSV file is
    # provided, a copy of Cardinal pooling config is used, which goes up to 96
    # samples. From 97 to 160 samples, the number of pools to create is 16.
    DEFAULT_NUMBER_OF_POOLS = 16

    # Returns the number of source plates from the purpose configuration.
    #
    # @return [Integer] The number of source plates.
    def number_of_source_plates
      @number_of_source_plates ||= purpose_config.dig(:creator_class, :args, :number_of_source_plates)
    end

    # Returns the WellFilter instance associated with this creator. The filter
    # uses the callback method labware_wells to get the list of wells to
    # filter, which specifies wells in passed state from the source plates.
    # The source_wells_for_pooling method is used to get the filtered wells.
    #
    #
    # @return [WellFilter] The WellFilter instance.
    def well_filter
      @well_filter ||= WellFilter.new(creator: self)
    end

    # Reurns all passed wells from the source plates in column order.
    #
    # @return [Array<Well>] An array of passed wells.
    def labware_wells
      source_plates.flat_map { |plate| plate.wells_in_columns.select(&:passed?) }
    end

    # Returns all source plates associated with the cleaned barcodes specified
    # by user using the Sequencescape API V2.
    #
    # @return [Array<Plate>] An array of source plates.
    def source_plates
      @source_plates ||=
        Sequencescape::Api::V2::Plate.find_all({ barcode: minimal_barcodes }, includes: SOURCE_PLATE_INCLUDES)
    end

    # Returns the source wells for pooling. The wells are filtered using the
    # well_filter.
    #
    # @return [Array<Well>] An array of source wells for pooling.
    def source_wells_for_pooling
      well_filter.filtered.map(&:first) # The first element is the well.
    end

    # Returns the pools for the destination plate.
    #
    # @return [Array<Pool>] An array of pools.
    def pools
      @pools ||= build_pools
    end

    # Sets the barcodes and minimal_barcodes instance variables. The
    # minimal_barcodes are derived from the barcodes by removing any blank
    # values and stripping whitespace from the remaining values.
    #
    # @param barcodes [Array<String>] An array of barcodes.
    def barcodes=(barcodes)
      @barcodes = barcodes
      @minimal_barcodes = barcodes.compact_blank.map(&:strip)
    end

    # Returns the number of pools based on the count of source wells for
    # pooling from the lookup table. If the count is not found in the table,
    # the default number of pools is returned.
    #
    # @return [Integer] The number of pools.
    def number_of_pools
      Rails.application.config.scrna_core_donor_pooling.fetch(source_wells_for_pooling.count, DEFAULT_NUMBER_OF_POOLS)
    end

    # Returns the tag depth for the given source well. The tag depth is the
    # position of the well in its pool. It is used used as an aliquot attribute
    # in the transfer request. It is recorded in Sequencescape to avoid tag
    # clashes.
    #
    # @param source_well [Well] The source well for which to retrieve the tag depth.
    # @return [String] The tag depth as a string, or nil if the well is not in a pool.
    def tag_depth(source_well)
      pools.each do |pool|
        return (pool.index(source_well) + 1).to_s if pool.index(source_well)
        # index + 1 incase of 0th index
      end
    end

    # Builds the pools for the destination plate. The wells are first grouped
    # by study and project, then split by donor_ids, and finally distributed
    # across pools.
    #
    # @return [Array<Array<Well>>] An array of well groups distributed across pools.
    def build_pools
      groups = group_by_study_and_project
      groups = split_groups_by_donor_ids(groups)
      distribute_samples_across_pools(groups)
    end

    private

    # Groups source wells for pooling by study and project. Wells are grouped
    # based on the study and project of the first aliquot in each well. Returns
    # an array of groups, where each group is an array of wells with the same
    # study and project.
    #
    # @return [Array<Array<Well>>] An array of well groups.
    def group_by_study_and_project
      source_wells_for_pooling.group_by { |well| [well.aliquots.first.study.id, well.aliquots.first.project.id] }.values
    end

    # Splits groups ensuring unique donor_ids within each group. Iterates over
    # each group, creating subgroups with wells from a unique donor. The first
    # occurrences of unique donor_ids are grouped, then the second occurrences,
    # and so on. This prevents combining samples with the same donor_id.
    #
    # @param groups [Array<Array<Well>>] Array of well groups to be split.
    # @return [Array<Array<Well>>] Array of subgroups split by donor ID.
    def split_groups_by_donor_ids(groups)
      groups.flat_map { |group| split_single_group_by_donor_ids(group) }
    end

    # Splits a single group of wells by donor_ids. Used by the
    # split_groups_by_donor_id method.
    #
    # @param group [Array<Well>] The group of wells to split.
    # @return [Array<Array<Well>>] An array of subgroups, each containing wells
    #   from a unique donor.
    def split_single_group_by_donor_ids(group)
      output = []
      while group.any?
        subgroup = []
        unique_donor_ids(group).each do |donor_id|
          index = group.index { |well| well.aliquots.sample.sample_metadata.donor_id == donor_id }
          subgroup << group.delete_at(index)
        end
        output << subgroup
      end
      output
    end

    # Returns the unique donor_ids from a group of wells. Used by the
    # split_single_group_by_donor_ids method.
    #
    # @param group [Array<Well>] The group of wells from which to retrieve donor_ids.
    # @return [Array<String>] An array of unique donor_ids.
    def unique_donor_ids(group)
      group.map { |well| well.aliquots.sample.sample_metadata.donor_id }.uniq
    end

    # Distributes samples across pools based on group sizes. It sorts the groups
    # by size and splits the largest group into two until the number of groups
    # equals the number of pools or until all groups have a size of 1.
    #
    # @param groups [Array<Array<Well>>] Array of well groups to be distributed.
    # @return [Array<Array<Well>>] Array of distributed groups.
    def distribute_samples_across_pools(groups)
      groups.sort_by!(&:size)
      while groups.any? && groups.last.size > 1 && groups.size < number_of_pools
        splits = (largest = groups.pop).each_slice(largest.size / 2).to_a
        groups.concat(splits).sort_by!(&:size)
      end
      groups
    end
  end
end

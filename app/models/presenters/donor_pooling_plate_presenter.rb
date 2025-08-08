# frozen_string_literal: true

module Presenters
  # Presenter for the scRNA Core donor pooling plate to validate the required
  # number of cells by study. If other features are necessary in the presenter,
  # they can be added here or the validation can be moved to the new one.
  class DonorPoolingPlatePresenter < StandardPresenter
    # The pooling tab is not relevant for this presenter as the wells are already pooled (tab shows future pooling
    # by submission strategy)
    self.pooling_tab = ''

    # Override the samples tab to display additional sample information for the pooled wells
    self.samples_partial = 'plates/pooled_wells_samples_tab'

    # Will always return true for this presenter
    def show_scrna_pooling?
      true
    end

    def study_project_groups_from_wells
      grouped_wells
    end

    def num_samples_per_pool(wells)
      counts = wells.filter_map { |well| well&.aliquots&.size }
      counts.uniq.size == 1 ? counts.first.to_s : counts.join(', ')
    end

    def get_source_wells(wells)
      wells.map { |well| well.position['name'] || 'Unknown' }.join(', ')
    end

    def cells_per_chip_well(well)
      config_key = Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key]
      pm = well.poly_metadata.detect do |pm|
        pm.key == config_key
      end

      value = pm&.value
      value&.to_i&.to_fs(:delimited) # Adds thousands separator for better readability
    end

    private

    # Groups wells by a key generated from each well's study and project.
    #
    # Iterates over all wells, selecting only those that are valid according to `valid_well?`.
    # For each valid well, computes a grouping key using `study_project_key(well)` and adds the well
    # to an array associated with that key in the resulting hash.
    #
    # @return [Hash] a hash where each key is the result of `study_project_key(well)` and each value
    # is an array of wells sharing that key.
    #
    def grouped_wells
      wells
        .select { |well| valid_well?(well) }
        .group_by { |well| study_project_key(well) }
        .flat_map do |key, group|
          group
            .group_by { |well| cells_per_chip_well(well) }
            .values
            .map { |subgroup| [key, subgroup] }
        end
    end

    def valid_well?(well)
      well && !well.aliquots.empty?
    end

    def study_project_key(well)
      aliquot = well.aliquots.first
      [aliquot.study.name, aliquot.project.name].join(' / ')
    end
  end
end

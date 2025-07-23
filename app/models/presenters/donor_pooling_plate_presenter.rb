# frozen_string_literal: true

module Presenters
  # Presenter for the scRNA Core donor pooling plate to validate the required
  # number of cells by study. If other features are necessary in the presenter,
  # they can be added here or the validation can be moved to the new one.
  class DonorPoolingPlatePresenter < StandardPresenter
    # The pooling tab is not relevant for this presenter as the wells are already pooled (tab shows future pooling
    # by submission strategy)
    #
    self.pooling_tab = ''

    def study_project_groups_from_wells
      grouped_wells.each.to_a
    end

    def num_samples_per_pool(group)
      group.map { |well| well&.aliquots&.size }.join(', ')
    end

    def get_source_wells(group)
      group.map { |well| well.position['name'] || 'Unknown' }.join(', ')
    end

    private

    def grouped_wells
      wells.each_with_object(Hash.new { |h, k| h[k] = [] }) do |well, groups|
        next unless valid_well?(well)

        key = study_project_key(well)
        groups[key] << well
      end
    end

    def valid_well?(well)
      well && !well.aliquots.empty?
    end

    def study_project_key(well)
      aliquot = well.aliquots.first
      "#{aliquot.study.name} / #{aliquot.project.name}"
    end

    self.page = 'show_pooling_info'
    # Override the samples tab to display additional sample information for the pooled wells
    self.samples_partial = 'plates/pooled_wells_samples_tab'
  end
end

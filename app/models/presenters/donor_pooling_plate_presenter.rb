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
      groups = Hash.new { |h, k| h[k] = [] }

      wells.compact
        .reject { |well| well.aliquots.empty? }
        .each do |well|
        key = "#{well.aliquots.first.study.name} / #{well.aliquots.first.project.name}"
        groups[key] << well # Store the well itself
      end

      groups.to_a
    end

    def num_samples_per_pool(group)
      group.map { |well| well&.aliquots&.size }.join(', ')
    end

    def get_source_wells(group)
      binding.pry
      group.map { |well| well.position['name'] || 'Unknown' }.join(', ')
    end

    self.page = 'show_pooling_info'
    # Override the samples tab to display additional sample information for the pooled wells
    self.samples_partial = 'plates/pooled_wells_samples_tab'
  end
end

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

    # Returns the CSV file links for the plate based on the configured states.
    # Checks for optional 'parent' parameter in link to not show button unless parent labware is of that purpose type.
    #
    # @return [Array<Array<String, Array>>] the CSV file links
    def csv_file_links
      parent_purposes = extract_parent_purposes
      file_links = fetch_file_links
      enabled_links = filter_enabled_links(file_links)
      parent_filtered_links = filter_by_parent_purpose(enabled_links, parent_purposes)
      links = build_csv_links(parent_filtered_links)
      links << ['Download Worksheet CSV', { format: :csv }] if csv.present?
      links
    end

    private

    def extract_parent_purposes
      labware.parents&.map { |parent| parent.purpose.name }
    end

    def fetch_file_links
      purpose_config.fetch(:file_links, [])
    end

    def filter_enabled_links(file_links)
      file_links.select { |link| can_be_enabled?(link&.states) }
    end

    def filter_by_parent_purpose(links, parent_purposes)
      links.select do |link|
        !link.respond_to?(:parent) ||
          link.parent.nil? ||
          (parent_purposes || []).include?(link.parent)
      end
    end

    def build_csv_links(links)
      links.map do |link|
        [
          link.name,
          [
            :plate,
            :export,
            { id: link.id, plate_id: human_barcode, format: :csv, **link.params || {} }
          ]
        ]
      end
    end

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

    # Override for RobotControlled method - to filter out unneeded robot links based on parent plate purpose
    # If the labware is in pending state, we want robots with both the parent and current purpose so we can do the
    # transfers.
    # If the labware is in passed state, we only want to see the robot to create the next downstream child. No need
    # to see robots for creating this current plate as it's already been transferred to.
    def suitable_for_labware?(config)
      main_match = find_main_match(config)
      return main_match_result_for_pending(config, main_match) if pending_with_main_match?(main_match)

      main_match.present?
    end

    def find_main_match(config)
      config.beds.detect do |_bed, bed_config|
        bed_config.purpose == purpose_name && bed_config.states.include?(labware.state)
      end
    end

    def pending_with_main_match?(main_match)
      labware.state == 'pending' && main_match
    end

    def main_match_result_for_pending(config, main_match)
      parent_purposes = extract_parent_purposes
      parent_match = find_parent_match(config, parent_purposes)
      main_match.present? && parent_match.present?
    end

    def find_parent_match(config, parent_purposes)
      config.beds.detect do |_bed, bed_config|
        parent_purposes&.include?(bed_config.purpose)
      end
    end
  end
end

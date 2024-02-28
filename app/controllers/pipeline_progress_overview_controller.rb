# frozen_string_literal: true

# Controller for table style view of work in progress for a pipeline
class PipelineProgressOverviewController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def show
    @pipeline_group_name = params[:id]
    @from_date = from_date(params)
    @purpose = params[:purpose]

    # Group related pipelines together
    pipelines_for_group = Settings.pipelines.retrieve_pipeline_config_for_group(@pipeline_group_name)

    @ordered_purpose_list = Settings.pipelines.combine_and_order_pipelines(pipelines_for_group)

    labware_records = arrange_labware_records(@ordered_purpose_list, from_date(params))

    # TODO: improve performance by only requesting full records when a @purpose is selected
    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
    @grouped_state_counts = count_states(@grouped)
  end

  def from_date(params)
    params[:date]&.to_date || Time.zone.today.prev_month
  end

  # Split out requests for the last purpose and the rest of the purposes so that
  # the labware for the last purpose can be filtered by those that have
  # ancestors including at least one purpose from the rest.
  def arrange_labware_records(ordered_purposes, from_date)
    page_size = 500

    specific_purposes = ordered_purposes.first(ordered_purposes.count - 1)
    specific_labware_records = retrieve_labware(page_size, from_date, specific_purposes)
    general_labware_records = retrieve_labware(page_size, from_date, ordered_purposes.last)

    specific_labware_records +
      filter_labware_records_by_ancestor_purpose_names(general_labware_records, specific_purposes)
  end

  # Filter a list of labware records such that we only keep those that have at
  # least one ancestor with a purpose from the given allow list.
  def filter_labware_records_by_ancestor_purpose_names(labware_records, purpose_names_list)
    labware_records.select do |labware|
      ancestor_purpose_names = labware.ancestors.map { |ancestor| ancestor.purpose.name }
      ancestor_purpose_names.any? { |purpose_name| purpose_names_list.include?(purpose_name) }
    end
  end

  # Retrieves labware through the Sequencescape V2 API
  # Combines pages into one list
  # Combines labware with and without children
  # Returns a list of Sequencescape::Api::V2::Labware
  def retrieve_labware(page_size, from_date, purposes)
    labware = query_labware(page_size, from_date, purposes, nil)
    labware_without_children = query_labware(page_size, from_date, purposes, false)

    # filter out labware without children from labware, matching on ID
    labware_without_children_ids = labware_without_children.to_set(&:id)
    labware_with_children = labware.reject { |labware_record| labware_without_children_ids.include?(labware_record.id) }

    labware_with_children.each { |labware_record| labware_record.has_children = true }
    labware_without_children.each { |labware_record| labware_record.has_children = false }

    labware_without_children + labware_with_children
  end

  def query_labware(page_size, from_date, purposes, with_children)
    labware_query =
      Sequencescape::Api::V2::Labware
        .select(
          { plates: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
          { tubes: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
          { purposes: 'name' }
        )
        .includes(:state_changes, :purpose, 'ancestors.purpose')
        .where(purpose_name: purposes, updated_at_gt: from_date)
    labware_query = labware_query.where(without_children: true) if with_children == false
    labware_query.order(:updated_at).per(page_size)

    Sequencescape::Api::V2.merge_page_results(labware_query)
  end

  # Returns following structure (example):
  #
  # {
  #   "LTHR Cherrypick" => [
  #     {
  #       :record => #<Sequencescape::Api::V2::Labware...>,
  #       :state => "pending"
  #     }
  #   ],
  #   "LTHR-384 PCR 1" => [{}]
  # }
  def mould_data_for_view(purposes, labware_records)
    {}.tap do |output|
      # Make sure there's an entry for each of the purposes, even if no records
      purposes.each { |p| output[p] = [] }

      labware_records.each do |rec|
        next unless rec.purpose

        state = decide_state(rec)
        next if state == 'cancelled'

        state_with_children = rec.has_children ? "#{state} (parent)" : state

        output[rec.purpose.name] << { record: rec, state: state, state_with_children: state_with_children }
      end
    end
  end

  def decide_state(labware)
    # TODO: the default of pending is a false assumption - see RVI cherrypick
    labware.state_changes&.max_by(&:id)&.target_state || 'pending'
  end

  # Counts of number of labware in each state for each purpose
  # Returns a hash with the following structure:
  # {
  #   "LTHR Cherrypick" => {
  #     "pending" => 5,
  #     "started" => 2
  #   },
  #   "LTHR-384 PCR 1" => {
  #     "pending" => 5,
  #     "started" => 2
  #   }
  # }
  def count_states(grouped)
    {}.tap do |output|
      grouped.each do |purpose, records|
        output[purpose] = records.group_by { |r| r[:state_with_children] }.transform_values(&:count)
      end
    end
  end
end

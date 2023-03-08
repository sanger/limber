# frozen_string_literal: true

# Controller for swimlane style view of work in progress for a pipeline
class PipelineWorkInProgressController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def show
    @pipeline_group_name = params[:id]

    # Group related pipelines together
    pipelines_for_group = Settings.pipelines.retrieve_pipeline_config_for_group(@pipeline_group_name)

    @ordered_purpose_list = Settings.pipelines.combine_and_order_pipelines(pipelines_for_group)

    labware_records = arrange_labware_records(@ordered_purpose_list)

    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
  end

  def from_date(params)
    params[:date]&.to_date || Time.zone.today.prev_month
  end

  # Split out requests for the last purpose and the rest of the purposes so that
  # the labware for the last purpose can be filtered by those that have
  # ancestors including at least one purpose from the rest.
  def arrange_labware_records(ordered_purposes)
    page_size = 500

    specific_purposes = ordered_purposes.first(ordered_purposes.count - 1)
    specific_labware_records = retrieve_labware(page_size, from_date(params), specific_purposes)
    general_labware_records = retrieve_labware(page_size, from_date(params), ordered_purposes.last)

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
  # Returns a list of Sequencescape::Api::V2::Labware
  def retrieve_labware(page_size, from_date, purposes)
    labware_query =
      Sequencescape::Api::V2::Labware
        .select(
          { plates: %w[uuid purpose labware_barcode state_changes created_at ancestors] },
          { tubes: %w[uuid purpose labware_barcode state_changes created_at ancestors] },
          { purposes: 'name' }
        )
        .includes(:state_changes, :purpose, 'ancestors.purpose')
        .where(without_children: true, purpose_name: purposes, created_at_gt: from_date)
        .order(:created_at)
        .per(page_size)

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

        output[rec.purpose.name] << { record: rec, state: state }
      end
    end
  end

  def decide_state(labware)
    labware.state_changes&.max_by(&:id)&.target_state || 'pending'
  end
end

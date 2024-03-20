# frozen_string_literal: true

# Controller for table style view of work in progress for a pipeline
class LabwareProgressController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def show
    page_size = 500

    # URL query parameters
    @pipeline_group_name = params[:id]
    @from_date = from_date(params)
    @purpose = params[:purpose]
    @progress = params[:progress]

    # Pipeline details

    # ["scRNA Core Cell Extraction Entry", "scRNA Core Cell Extraction Seq", "scRNA Core Cell Extraction Spare"]
    @pipelines_for_group = Settings.pipelines.retrieve_pipeline_config_for_group(@pipeline_group_name)

    # ["LRC Blood Vac", "LRC Blood Aliquot", "LRC Blood Bank", "LRC PBMC Bank", "LRC Bank Seq", "LRC Bank Spare"]
    @ordered_purpose_names = Settings.pipelines.combine_and_order_pipelines(@pipelines_for_group)

    # {
    #   'LRC Blood Vac' => {
    #     'scRNA Core Cell Extraction Entry' => {
    #       parents: [],
    #       child: 'LRC Blood Aliquot'
    #     }
    #   },
    #   'LRC Blood Aliquot' => {
    #     'scRNA Core Cell Extraction Entry' => {
    #       parents: ['LRC Blood Vac'],
    #       child: 'LRC Blood Bank'
    #     }
    #   },
    # ...
    # }
    @purpose_pipeline_details =
      Settings.pipelines.purpose_to_pipelines_map(@ordered_purpose_names, @pipelines_for_group)

    # {
    #   'scRNA Core Cell Extraction Entry' => ['LRC Blood Vac', 'LRC Blood Aliquot', 'LRC Blood Bank'],
    #   'scRNA Core Cell Extraction Seq' => ['LRC Blood Bank', 'LRC PBMC Bank', 'LRC Bank Seq'],
    #   'scRNA Core Cell Extraction Spare' => ['LRC PBMC Bank', 'LRC Bank Spare']
    # }
    @ordered_purpose_names_for_pipelines = order_purposes_for_pipelines(@pipelines_for_group)

    # Labware results
    @labware =
      compile_labware_for_purpose(@ordered_purpose_names, page_size, @from_date, @ordered_purpose_names, @progress)
  end

  def from_date(params)
    params[:date]&.to_date || Time.zone.today.prev_month
  end

  def order_purposes_for_pipelines(pipeline_names)
    pipeline_names.index_with { |pipeline_name| Settings.pipelines.order_pipeline(pipeline_name) }
  end

  # Filter out labware that is not related of the given list of purpose names.
  # A labware is related to a purpose if it is that purpose or has an ancestor
  # that is that purpose.
  def filter_labware_by_related_purpose(labware_records, purpose_names)
    labware_records.select do |labware|
      purpose_names.include?(labware.purpose.name) ||
        labware.ancestors.any? { |ancestor| purpose_names.include?(ancestor.purpose.name) }
    end
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
    labware_query.per(page_size)

    Sequencescape::Api::V2.merge_page_results(labware_query)
  end

  def decide_state(labware)
    # TODO: #1619 Y24-023 the default of pending is a false assumption - see RVI cherrypick
    labware.state_changes&.max_by(&:id)&.target_state || 'pending'
  end

  def add_children_metadata(labware_records, has_children)
    labware_records.each do |labware_record|
      labware_record.has_children = has_children
      labware_record.progress = has_children ? 'used' : 'ongoing'
    end
  end

  def add_state_metadata(labware_records)
    labware_records.each { |labware_record| labware_record.state = decide_state(labware_record) }
  end

  def query_labware_with_children(page_size, from_date, purposes)
    labware_all = query_labware(page_size, from_date, purposes, nil)
    labware_without_children = query_labware(page_size, from_date, purposes, false)

    # filter out labware without children from labware, matching on ID
    labware_without_children_ids = labware_without_children.to_set(&:id)
    labware_with_children =
      labware_all.reject { |labware_record| labware_without_children_ids.include?(labware_record.id) }

    labware_with_children = add_children_metadata(labware_with_children, true)
    labware_without_children = add_children_metadata(labware_without_children, false)

    labware = labware_without_children + labware_with_children
    add_state_metadata(labware)
  end

  # Filter labware records by progress. If progress is nil, return all labware
  def filter_labware_by_progress(labware_records, progress)
    return labware_records if progress.nil?

    case progress
    when 'used'
      labware_records.select(&:has_children)
    when 'ongoing'
      labware_records.reject(&:has_children)
    end
  end

  # Given a list of purposes, retrieve labware records for those purposes and
  # their ancestors purposes, and filter out any from another pipeline or that have been cancelled.
  def compile_labware_for_purpose(query_purposes, page_size, from_date, ordered_purposes, progress)
    related_purposes = ordered_purposes.first(ordered_purposes.count - 1)

    labwares = query_labware_with_children(page_size, from_date, query_purposes)
    labwares = labwares.reject { |labware| labware.state == 'canceled' }
    labwares = filter_labware_by_related_purpose(labwares, related_purposes)
    labwares = filter_labware_by_progress(labwares, progress)
    labwares.sort_by(&:updated_at).reverse
  end
end

# frozen_string_literal: true

# Controller for swimlane style view of work in progress for a pipeline
class PipelineWorkInProgressController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def index
    # TODO: In future, add 'pipeline_group' or similar to pipeline config ymls, to group related ones together
    # Then we can avoid hardcoding '@pipeline' and 'heron_pipelines' here, and give them a list of pipelines to choose from
    @pipeline = 'Heron'

    # TODO: test including the 'Heron 384 Tailed MX' pipeline - might cause an issue as there might be loads of tubes in the final purpose
    heron_pipelines = ['Heron-384 Tailed A', 'Heron-384 Tailed B']
    @ordered_purpose_list = Settings.pipelines.combine_and_order_pipelines(heron_pipelines)

    page_size = 500

    labware_records = retrieve_labware(page_size, from_date(params), @ordered_purpose_list)
    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
  end

  def from_date(params)
    params[:date]&.to_date || Time.zone.today.prev_month
  end

  # Retrieves labware through the Sequencescape V2 API
  # Combines pages into one list
  # Returns a list of Sequencescape::Api::V2::Labware
  def retrieve_labware(page_size, from_date, purposes)
    labware_query = Sequencescape::Api::V2::Labware
                    .select({ plates: %w[uuid purpose labware_barcode state_changes created_at ancestors] },
                            { tubes: %w[uuid purpose labware_barcode state_changes created_at ancestors] },
                            { purposes: 'name' })
                    .includes(:state_changes, :purpose)
                    .where(without_children: true, purpose_name: purposes, created_at_gt: from_date)
                    .order(:created_at)
                    .per(page_size)

    labware_query = labware_query.includes(:ancestors) unless reduce_information_for_performance(from_date)

    merge_page_results(labware_query, page_size)
  end

  # Retrieves results of query builder (JsonApiClient::Query::Builder) page by page
  # and combines them into one list
  def merge_page_results(query_builder, page_size)
    all_records = []
    page_num = 1
    num_retrieved = page_size
    while num_retrieved == page_size
      current_page = query_builder.page(page_num).to_a
      num_retrieved = current_page.size
      all_records += current_page
      page_num += 1
    end

    all_records
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

  def reduce_information_for_performance(from_date)
    @reduce_information_for_performance ||= from_date < Time.zone.today.prev_month
  end
end

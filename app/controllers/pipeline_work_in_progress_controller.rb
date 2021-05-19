# frozen_string_literal: true

class PipelineWorkInProgressController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def index
    # TODO: In future, add 'pipeline_group' or similar to pipeline config ymls, to group related ones together
    # Then we can avoid hardcoding '@pipeline' and 'heron_pipelines' here, and give them a list of pipelines to choose from
    @pipeline = '"Heron"'

    # TODO: test including the 'Heron 384 Tailed MX' pipeline - might cause an issue as there might be loads of tubes in the final purpose
    heron_pipelines = ['Heron-384 Tailed A', 'Heron-384 Tailed B']
    @ordered_purpose_list = Settings.pipelines.combine_and_order_pipelines(heron_pipelines)

    page_size = 500

    labware_records = retrieve_labware(page_size, from_date(params), @ordered_purpose_list)
    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
  end

  def from_date(params)
    params[:date]&.to_date || Date.today.prev_month
  end

  # Retrieves labware through the Sequencescape V2 API
  # Combines pages into one list
  # Returns a list of Sequencescape::Api::V2::Labware
  def retrieve_labware(page_size, from_date, purposes)
    labware_query = Sequencescape::Api::V2::Labware
      .select(
        {plates: ["uuid", "purpose", "labware_barcode", "state_changes", "created_at", "ancestors"]},
        {tubes: ["uuid", "purpose", "labware_barcode", "state_changes", "created_at", "ancestors"]},
        {purposes: "name"}
      )
      .includes(:state_changes)
      .includes(:purpose)
      .includes(:ancestors)
      .where(
                without_children: true,
        purpose_name: purposes,
        created_at_gt: from_date
      )
      .order(:created_at)
      .per(page_size)

      merge_page_results(labware_query, page_size)
  end

  # Retrieves results of query builder (JsonApiClient::Query::Builder) page by page
  # and combines them into one list
  def merge_page_results(query_builder, page_size)
    all_records = []
    page_num = 1
    num_retrieved = page_size
    while num_retrieved == page_size
      puts "page_num: #{page_num}"

      current_page = query_builder.page(page_num).to_a
      num_retrieved = current_page.size
      puts "num_retrieved: #{num_retrieved}"

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
  #       :record => #<Sequencescape::Api::V2::Labware:@attributes={"type"=>"plates", "id"=>"1234", "uuid"=>"12a34b5c-defg-67hi-8jkl-mn901opq2345", "labware_barcode"=>#<LabwareBarcode:0x00007ff16e5f06b0 @human="DN123456D", @machine="DN123456D", @ean13="1234567890123">, "created_at"=>2021-05-04 12:19:32 +0100}>,
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

        state = rec.state_changes&.sort_by { |sc| sc.id }&.last&.target_state || 'pending'
        next if state == 'cancelled'

        labware_data = {record: rec, state: state}

        output[rec.purpose.name] << labware_data
      end
    end
  end
end

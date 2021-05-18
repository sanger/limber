# frozen_string_literal: true

class PipelineWorkInProgressController < ApplicationController
  # Retrieves data from Sequencescape and populates variables to be used in the UI
  def index
    # TODO: how can we avoid hardcoding this? Problem is there are multiple relevant pipelines we want to display in one.
    @pipeline = '"Heron"'

    # TODO: test including the 'Heron 384 Tailed MX' pipeline - might cause an issue as there might be loads of tubes in the final purpose
    pipeline_configs = Settings.pipelines.select{ |pipeline| ['Heron-384 Tailed A', 'Heron-384 Tailed B'].include? pipeline.name }
    @ordered_purpose_list = combine_and_order_pipelines(pipeline_configs)

    page_size = 500

    labware_records = retrieve_labware(page_size, from_date(params), @ordered_purpose_list)
    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
  end

  def from_date(params)
    params[:date]&.to_date || Date.today.prev_month
  end

  # Builds a flat list of purposes in a sensible order from the relationships config
  # Allowing the config hash to be in any order
  # For example getting from this:
  #
  # {
  #   "LTHR Cherrypick" => [ "LTHR-384 RT-Q" ],
  #   "LTHR-384 RT-Q" => [ "LTHR-384 PCR 1", "LTHR-384 PCR 2" ],
  #   "LTHR-384 RT" => [ "LTHR-384 PCR 1", "LTHR-384 PCR 2" ],
  #   "LTHR-384 PCR 1" => [ "LTHR-384 Lib PCR 1" ],
  #   "LTHR-384 Lib PCR 1" => [ "LTHR-384 Lib PCR pool" ],
  #   "LTHR-384 PCR 2" => [ "LTHR-384 Lib PCR 2" ],
  #   "LTHR-384 Lib PCR 2" => [ "LTHR-384 Lib PCR pool" ]
  # }
  #
  # To this:
  #
  # ["LTHR Cherrypick", "LTHR-384 RT", "LTHR-384 RT-Q", "LTHR-384 PCR 1", "LTHR-384 PCR 2", "LTHR-384 Lib PCR 1", "LTHR-384 Lib PCR 2", "LTHR-384 Lib PCR pool"]
  def combine_and_order_pipelines(pipeline_configs)
    # puts "pipeline configs:"
    # pipeline_configs.each do |pc|
    #   puts pc.inspect
    # end
    ordered_purpose_list = []

    combined_relationships = {}
    pipeline_configs.each do |pc|
      pc.relationships.each do |key, value|
        combined_relationships[key] ||= []
        combined_relationships[key] << value
      end
    end

    all_purposes = (combined_relationships.keys + combined_relationships.values.flatten).uniq

    # Any purposes with no 'child' purposes should go at the end of the list
    without_child = all_purposes.select { |p| !(combined_relationships.key? p) }

    while combined_relationships.size > 0
      # Find any purposes with no 'parent' purposes - to go on the front of the list
      with_parent = combined_relationships.values.flatten.uniq
      without_parent = all_purposes - with_parent
      raise "Pipeline config can't be flattened into a list of purposes" if without_parent.empty? # important to prevent infinite looping

      ordered_purpose_list += without_parent

      # Delete the nodes that have been added, making the next set of purposes have no parent
      # So we can use the same technique again in the next iteration
      without_parent.each { |n| combined_relationships.delete(n) }

      # Refresh the all_purposes list for the next iteration
      all_purposes = (combined_relationships.keys + combined_relationships.values.flatten).uniq
    end

    # When we've run out of 'parent' purposes, add the final ones on the end
    ordered_purpose_list += without_child
    ordered_purpose_list
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

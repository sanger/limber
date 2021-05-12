# frozen_string_literal: true

class PipelineWorkInProgressController < ApplicationController
  def index
    # TODO: how can we avoid hardcoding this? Problem is there are multiple relevant pipelines we want to display in one.
    @pipeline = '"Heron"'

    # TODO: test including the 'Heron 384 Tailed MX' pipeline - might cause an issue as there might be loads of tubes in the final purpose
    pipeline_configs = Settings.pipelines.select{ |pipeline| ['Heron-384 Tailed A', 'Heron-384 Tailed B'].include? pipeline.name }
    @ordered_purpose_list = combine_and_order_pipelines(pipeline_configs)

    page_size = 500
    param_date = params[:date]&.to_date
    from_date = param_date ? param_date : Date.today.prev_month

    labware_records = retrieve_labware(page_size, from_date, @ordered_purpose_list)
    @grouped = mould_data_for_view(@ordered_purpose_list, labware_records)
  end
end


# TODO: refactor to make less wordy and more readable
def combine_and_order_pipelines(pipeline_configs)
  ordered_purpose_list = []
  combined_relationships = {}
  all_purposes = []

  pipeline_configs.each do |pipeline_config|
    pipeline_config.relationships.each do |key, value|
      if combined_relationships.key? key
        combined_relationships[key] << value
      else
        combined_relationships[key] = [value]
      end

      all_purposes << key
      all_purposes << value
    end
  end

  all_purposes = all_purposes.uniq
  ending = all_purposes.select { |pur| !(combined_relationships.key? pur) }

  while combined_relationships.size > 0 # TODO: check if this could ever go infinite
    children = combined_relationships.values.flatten.uniq
    no_parent = all_purposes - children

    ordered_purpose_list += no_parent

    no_parent.each { |n| combined_relationships.delete(n) }

    all_purposes = []
    combined_relationships.each do |key, value|
      all_purposes << key
      all_purposes += value
    end
    all_purposes = all_purposes.uniq
  end

  ordered_purpose_list += ending

  ordered_purpose_list
end


def retrieve_labware(page_size, from_date, purposes)
  p = Sequencescape::Api::V2::Labware
    .select(
      {plates: ["uuid", "purpose", "labware_barcode", "state_changes", "created_at"]},
      {tubes: ["uuid", "purpose", "labware_barcode", "state_changes", "created_at"]},
      {purposes: "name"}
    )
    .includes(:state_changes)
    .includes(:purpose)
    .where(
      without_children: true,
      purpose_name: purposes,
      created_at_gt: from_date
    )
    .order(:created_at)
    .per(page_size)

  all_records = []
  page_num = 1
  num_retrieved = page_size
  while num_retrieved == page_size
    puts "page_num: #{page_num}"

    num_retrieved = p.page(page_num).to_a.size
    puts "num_retrieved: #{num_retrieved}"

    all_records += p.page(page_num).to_a
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
  output = {}
  # Make sure there's an entry for each of the purposes, even if no records
  purposes.each { |p| output[p] = [] }

  labware_records.each do |rec|
    next unless rec.purpose

    state = rec.state_changes&.sort_by { |sc| sc.id }&.last&.target_state || 'pending'
    next if state == 'cancelled'

    labware_data = {record: rec, state: state}

    output[rec.purpose.name] << labware_data
  end

  output
end
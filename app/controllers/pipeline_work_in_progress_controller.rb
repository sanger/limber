# frozen_string_literal: true

class PipelineWorkInProgressController < ApplicationController
  def index
    # haven't tested it yet including the 'Heron 384 Tailed MX' pipeline - might cause an issue as there might be loads of tubes in the final purpose
    pipeline_configs = Settings.pipelines.select{ |pipeline| ['Heron-384 Tailed A', 'Heron-384 Tailed B'].include? pipeline.name }
    puts "*** pipeline_configs: #{pipeline_configs} ***"

    @ordered_purpose_list = combine_and_order_pipelines(pipeline_configs)

    @pipeline = '"Heron"'
    page_size = 500

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
        purpose_name: @ordered_purpose_list,
        created_at_gt: Date.today.prev_month
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

    records = all_records
    # records = p.page(1).to_a # use instead of line above to just display the first page
    @num_records = records.size

    @grouped = {}
    records.each do |rec|
      purpose_name = rec.purpose&.name
      if @grouped.key? purpose_name
        @grouped[purpose_name] << rec
      else
        @grouped[purpose_name] = [rec]
      end
    end
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
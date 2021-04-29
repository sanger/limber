# frozen_string_literal: true

class PipelineWorkInProgressController < ApplicationController
  # Get labware that don't have children
  # Of the right purposes for the pipeline
  # Display: purpose, barcode, state (for now)
  # Filter out ones that are complete, in the final stage of the pipeline

  # Questions:
  # How quick can we load the page?
  # How many plates will this be?
  # Does it display the same plates as the Trello board?
  def index
    puts "*** index **"
    @pipeline = '"Heron"'

    p = Sequencescape::Api::V2::Labware
      .select(
        {plates: ["uuid", "purpose", "labware_barcode", "state_changes"]},
        {tubes: ["uuid", "purpose", "labware_barcode", "state_changes"]},
        {purposes: "name"}
      )
      .includes(:state_changes)
      .includes(:purpose)
      .where(
        without_children: true,
        purpose_name: [ # cherrypick id 395
          "LTHR Cherrypick","LTHR-384 RT-Q","LTHR-384 PCR 1","LTHR-384 PCR 2","LTHR-384 Lib PCR 1","LTHR-384 Lib PCR 2","LTHR-384 Lib PCR pool","LTHR-384 Pool XP"
        ]
      )
      .per(500)

    # TODO: do tubes as well
    # p = Sequencescape::Api::V2::Plate.select("uuid","labware_barcode","purpose","state", {purposes: "name"})
    #   # .includes(:state_changes)
    #   .includes(:purpose)
    #   .where(
    #     without_children: true,
    #     purpose_name: [ # cherrypick id 395
    #       "LTHR Cherrypick","LTHR-384 RT-Q","LTHR-384 PCR 1","LTHR-384 PCR 2","LTHR-384 Lib PCR 1","LTHR-384 Lib PCR 2","LTHR-384 Lib PCR pool","LTHR-384 Pool XP"
    #     ]
    #   )

    # binding.pry

    all_records = []
    page_num = 1
    page_size = 100
    while page_size == 100
      puts "page_num: #{page_num}"

      page_size = p.page(page_num).to_a.size
      puts "page size: #{page_size}"

      all_records += p.page(page_num).to_a
      page_num += 1
    end

    records = all_records
    # records = p.page(1).to_a
    @num_records = records.size

    @grouped = {}
    records.each do |rec|
      # puts rec.inspect
      # binding.pry
      purpose_name = rec.purpose&.name
      if @grouped.key? purpose_name
        @grouped[purpose_name] << rec
      else
        @grouped[purpose_name] = [rec]
      end
    end

    # puts "*** grouped: #{grouped.class} ***"
    # puts "*** grouped: #{grouped} ***"

  end
end

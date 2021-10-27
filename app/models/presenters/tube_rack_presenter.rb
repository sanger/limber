# frozen_string_literal: true

require_dependency 'presenters/presenter'

module Presenters
  # Basic core presenter class for tube racks
  # Over time, expect this class to use composition to handle the need for different
  # rack presenters based on the tubes within.
  class TubeRackPresenter
    include Presenters::Presenter
    include TubeRackWalking

    self.summary_partial = 'tube_racks/summaries/default'
    self.aliquot_partial = 'tube_aliquot'

    delegate_missing_to :labware

    def state
      'pending'
    end

    def priority
      all_tubes.map(&:priority).max
    end

    def title
      "#{purpose_name} : #{all_tubes.map(&:purpose_name).uniq.to_sentence}"
    end

    def tube_failing_applicable?
      false
    end

    def label
      Labels::TubeRackLabel.new(labware)
    end

    def tube_labels
      all_tubes.map { |tube| Labels::TubeLabel.new(tube) }
    end

    def csv_file_links
      purpose_config.fetch(:file_links, []).map do |link|
        [link.name, [:limber_tube_rack, :export, { id: link.id, limber_tube_rack_id: human_barcode, format: :csv }]]
      end
    end

    private

    def all_tubes
      @all_tubes ||= labware.racked_tubes.map(&:tube)
    end
  end
end

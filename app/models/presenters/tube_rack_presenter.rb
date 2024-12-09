# frozen_string_literal: true

module Presenters
  # Basic core presenter class for tube racks
  # Over time, expect this class to use composition to handle the need for different
  # rack presenters based on the tubes within.
  class TubeRackPresenter
    include Presenters::Presenter
    include Presenters::RobotControlled
    include Presenters::Statemachine::Standard
    include Presenters::CreationBehaviour
    include TubeRackWalking

    self.summary_partial = 'tube_racks/summaries/default'
    self.aliquot_partial = 'tube_aliquot'
    self.summary_items = {
      'Barcode' => :barcode,
      'Number of tubes' => :number_of_tubes,
      'Rack type' => :purpose_name,
      'Tube type' => :tube_purpose_names,
      'Created on' => :created_on
    }

    delegate_missing_to :labware

    # Purpose, state and barcode are delegated to the tube rack.
    delegate :purpose, :state, :human_barcode, to: :labware

    def priority
      all_tubes.map(&:priority).max
    end

    def title
      "#{purpose_name} : #{tube_purpose_names}"
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
      purpose_config
        .fetch(:file_links, [])
        .select { |link| can_be_enabled?(link&.states) }
        .map do |link|
          [link.name, [:limber_tube_rack, :export, { id: link.id, limber_tube_rack_id: human_barcode, format: :csv }]]
        end
    end

    def comment_title
      "#{human_barcode} - #{purpose_name} : #{tube_purpose_names}"
    end

    def number_of_tubes
      all_tubes.count
    end

    private

    def tube_purpose_names
      all_tubes.map(&:purpose_name).uniq.to_sentence
    end

    def all_tubes
      @all_tubes ||= labware.racked_tubes.map(&:tube)
    end
  end
end

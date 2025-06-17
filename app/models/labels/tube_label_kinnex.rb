# frozen_string_literal: true

class Labels::TubeLabelKinnex < Labels::TubeLabel # rubocop:todo Style/Documentation
  def first_line
    labware.name.presence
  end

  def second_line
    workline_identifier
  end

  private

  # When printed from the parent plate's presenter, labware_sources is needed because the labware
  # is an instance of Presenters::TubesWithSources.
  # When printed from the tube's presenter, transfer_requests_as_target is needed because the labware
  # is an instance of Sequencescape::Api::V2::Tube.
  def workline_identifier
    if labware.respond_to?(:labware_sources)
      labware.labware_sources.first&.name
    else
      labware.transfer_requests_as_target.first&.source_asset&.name
    end
  end
end

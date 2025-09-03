# frozen_string_literal: true

class Labels::TubeLabelKinnex < Labels::TubeLabel # rubocop:todo Style/Documentation
  CUSTOM_INCLUDES = [
    :purpose,
    'transfer_requests_as_target.source_asset',
    'receptacle.aliquots.request.request_type',
    'receptacle.requests_as_source.request_type'
  ].freeze

  def attributes
    super.merge(
      first_line: first_line,
      second_line: second_line,
      barcode: labware.barcode.human
    )
  end

  # This function is used to fetch the labware with the necessary includes for the label.
  # It uses the Sequencescape API to find the labware by its UUID and includes the custom includes defined above.
  # The labware is already set for the `labware` variable but we want to fetch the `transfer_requests_as_target`
  # association to get the source asset name for the second line of the label. This was not done at
  # `app/sequencescape/sequencescape/api/v2/tube.rb` as it affects the performance of the API call.
  #
  # returns [Sequencescape::Api::V2::Tube] The labware with the necessary includes.
  def labware_with_includes
    @labware_with_includes ||= Sequencescape::Api::V2::Tube.includes(*CUSTOM_INCLUDES).find(uuid: labware.uuid).first
  end

  def first_line
    labware_with_includes.name.presence
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
      labware_with_includes.transfer_requests_as_target.first&.source_asset&.name
    end
  end
end

# frozen_string_literal: true

# Include in a presenter to add support for filtering out multiplexed child creation options
# rubocop:disable Metrics/ModuleLength
module Presenters::FilterMxChildrenCreationBehaviour
  DESCENDANT_TUBE_INCLUDES = [
    'receptacle',
    'aliquots',
    'aliquots.request',
    'aliquots.request.request_type',
    'receptacle.requests_as_source.request_type'
  ].join(',')

  # Prevent the multiplexing child labware button from appearing if a valid child labware already exists
  def allow_specific_child_creation?
    # Check if any downstream tubes exist matching the requirements
    downstream_mx_tubes = find_downstream_mx_tubes

    # If we find downstream multiplexed tubes, we should prevent the specific child creation
    downstream_mx_tubes.blank?
  end

  def suggested_options_warnings
    @suggested_options_warnings ||= ActiveModel::Errors.new(self)
  end

  def suggested_purpose_options
    suggested_options = identify_suggested_purpose_options

    if allow_specific_child_creation?
      suggested_options
    else
      # filter out the purpose(s) specified in the purpose config if we cannot allow the child creation yet
      display_warning_and_filter_child_options(suggested_options)
    end
  end

  private

  def child_tube_purposes_to_limit
    @child_tube_purposes_to_limit ||= determine_child_tube_purposes_to_limit
  end

  def determine_child_tube_purposes_to_limit
    # guard against basic presenter config line without args
    return [] if purpose_config[:presenter_class].is_a?(String)

    purpose_config.dig(:presenter_class, :args, :downstream_mx_tube, :child_tube_purposes_to_limit) || []
  end

  def find_downstream_mx_tubes
    return [] if @labware.descendants.blank?

    @labware.descendants.each_with_object([]) do |labware_descendant, arr|
      next unless tube_matches_requirements?(labware_descendant)

      next unless tube_request_matches_requirements?(labware_descendant)

      arr << labware_descendant
    end
  end

  def tube_matches_requirements?(labware_descendant)
    return false unless labware_descendant.tube?

    return false unless tube_purpose?(labware_descendant)

    true
  end

  # Check that the tube has a request of the specified type and state
  # Returns true if all checks pass, false otherwise
  def tube_request_matches_requirements?(labware_descendant)
    child_tube = fetch_child_tube(labware_descendant)
    return false unless child_tube

    child_tube_reqs = fetch_child_tube_requests(child_tube)
    return false if child_tube_reqs.empty?

    # look for a request matching the type and allowed state
    matching_request?(child_tube_reqs)
  end

  def matching_request?(child_tube_reqs)
    acceptable_request_found = false
    child_tube_reqs.each do |child_tube_req|
      tube_req_type = fetch_tube_req_type(child_tube_req)

      next unless tube_req_type.present? && req_type_for_multiplexing?(tube_req_type)

      acceptable_request_found = true
      break
    end

    acceptable_request_found
  end

  def tube_purpose?(labware_descendant)
    child_tube_purposes_to_limit.include?(labware_descendant.purpose.name)
  end

  def fetch_child_tube(labware_descendant)
    Sequencescape::Api::V2::Tube.find_by(uuid: labware_descendant.uuid, includes: DESCENDANT_TUBE_INCLUDES)
  end

  def fetch_child_tube_requests(child_tube)
    # assumption that all aliquots will have same request
    Array(child_tube.aliquots.first.request) || []
  end

  def fetch_tube_req_type(child_tube_req)
    child_tube_req.request_type
  end

  def req_type_for_multiplexing?(tube_req_type)
    tube_req_type.for_multiplexing
  end

  # rubocop:disable Metrics/MethodLength
  def display_warning_and_filter_child_options(suggested_options)
    # NB. uses lazy.reject to return an enumerator, not an array, because that breaks creation behaviour
    # in the construct buttons method where there is a force on the scope
    suggested_options.lazy.reject do |(_uuid, settings)|
      if child_tube_purposes_to_limit.include?(settings[:name])
        suggested_options_warnings.add(
          :tube,
          "- NB. the #{settings[:name]} tube creation button has been hidden as the one specified by the library " \
          'multiplexing Submission has already been created (see Children in the summary Relatives tab).'
        )
        true
      else
        false
      end
    end
  end

  # rubocop:enable Metrics/MethodLength

  # This identifies possible child purposes based on the active pipelines for this labware
  # and the compatible purposes defined in the configuration files.
  def identify_suggested_purpose_options
    active_pipelines
      .lazy
      .filter_map do |pipeline, _store|
        child_name = pipeline.child_for(labware.purpose_name)
        uuid, settings =
          compatible_purposes.detect { |_purpose_uuid, purpose_settings| purpose_settings[:name] == child_name }
        next unless uuid

        [uuid, settings.merge(filters: pipeline.filters)]
      end
      .uniq
  end
end

# rubocop:enable Metrics/ModuleLength

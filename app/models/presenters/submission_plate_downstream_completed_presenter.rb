# frozen_string_literal: true

module Presenters
  #
  # This Presenter presents the user with a selection of submission options,
  # and allows them to generate corresponding Sequencescape submissions.
  # It only presents these options when certain pre-requisites are met.
  # Namely, a downstream tube labware of specified purpose must have a specified
  # state, and must have sequencing requests of the specified type in the specified state.
  #
  # Designed for Ultima where we loop back to perform rebalancing. But only after
  # the initial sequencing run has been completed.
  #
  # Submission options are defined by the submission_options config in the
  # purposes/*.yml file. Structure is:
  # <button text>:
  #   template_name: <submission template name>
  #   downstream_seq_tube:
  #     purpose: <downstream tube purpose> e.g. 'UPF EqVol Norm'
  #     state: <downstream tube state> e.g. 'passed'
  #     request_type: <sequencing request type> e.g. 'ultima_sequencing'
  #     N.B. The NPG team updates the state of sequencing requests
  #     request_allowed_states: [<request state>, <request state>, etc.] e.g. ['completed', 'failed']
  #   request_options:
  #     <request_option_key>: <request_option_value>
  #     ...
  class SubmissionPlateDownstreamCompletedPresenter < PlatePresenter
    include Presenters::Statemachine::SubmissionWhenPassed
    include Presenters::Statemachine::AllowsLibraryPassing
    include Presenters::SubmissionBehaviour

    self.summary_items = {
      'Barcode' => :barcode,
      'Number of wells' => :number_of_wells,
      'Plate type' => :purpose_name,
      'Current plate state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    TUBE_INCLUDES = 'receptacle,aliquots,aliquots.request,aliquots.request.request_type'

    # Overridden from SubmissionBehaviour
    # Check for submission already in progress
    # If not, check that the first sequencing run has completed by checking the downstream tubes
    def allow_new_submission?
      # No more than one submission of a type can be active at time for a given labware.
      # Prevent new submissions if any are currently in progress, as the submission type
      # is currently not available.
      submissions_in_progress = pending_submissions? || active_submissions?
      return false if submissions_in_progress

      # Next check if any downstream tubes exist matching the requirements (there may be more than one
      # depending on pooling and repeats, we need at least one to have completed the first run)
      downstream_sequenced_tubes = find_downstream_sequenced_tubes

      # If there are no downstream tube(s) yet, we have completed the first run so we cannot create the
      # new submission
      return false if downstream_sequenced_tubes.blank?

      # We found at least one downstream tube matching the requirements so we can allow a new submission
      true
    end

    private

    def downstream_seq_tube_purpose
      @downstream_seq_tube_purpose ||=
        purpose_config.dig(:presenter_class, :args, :downstream_seq_tube, :purpose)
    end

    def downstream_seq_tube_state
      @downstream_seq_tube_state ||=
        purpose_config.dig(:presenter_class, :args, :downstream_seq_tube, :state)
    end

    def downstream_seq_request_type_name
      @downstream_seq_request_type_name ||=
        purpose_config.dig(:presenter_class, :args, :downstream_seq_tube, :request_type)
    end

    def downstream_seq_tube_request_allowed_states
      @downstream_seq_tube_request_allowed_states ||=
        Array(purpose_config.dig(:presenter_class, :args, :downstream_seq_tube, :request_allowed_states))
    end

    # Find downstream sequenced tubes matching the requirements
    # Assumptions
    # - plate will have one or more downstream tubes for sequencing if the first run has completed
    # - downstream tube will be of type 'Tube'
    # - downstream tube will have a specific purpose
    # - downstream tube will have a specific state
    # - downstream tube will have a sequencing request of the specified type
    # - downstream tube will have a sequencing request that matches to a list of specified allowed states
    def find_downstream_sequenced_tubes
      @labware.descendants.each_with_object([]) do |labware_descendant, arr|
        next unless tube_matches_requirements?(labware_descendant)

        next unless tube_request_matches_requirements?(labware_descendant)

        arr << labware_descendant
      end
    end

    # Check that the labware descendant is a tube of the specified purpose and state
    # Returns true if all checks pass, false otherwise
    def tube_matches_requirements?(labware_descendant)
      return false unless tube_type?(labware_descendant)
      return false unless tube_purpose?(labware_descendant)

      false unless tube_state?(labware_descendant)
    end

    # Check that the tube has a request of the specified type and state
    # Returns true if all checks pass, false otherwise
    def tube_request_matches_requirements?(labware_descendant)
      v2_tube = fetch_v2_tube(labware_descendant)
      return false unless v2_tube

      v2_tube_req = fetch_v2_tube_request(v2_tube)
      return false unless v2_tube_req

      vtube_req_type = fetch_vtube_req_type(v2_tube_req)

      return false unless vtube_req_type && req_type_name_matches?(vtube_req_type)
      return false unless allowed_request_state?(v2_tube_req)

      true
    end

    def tube_type?(labware_descendant)
      labware_descendant.type == 'tubes'
    end

    def tube_purpose?(labware_descendant)
      labware_descendant.purpose.name == downstream_seq_tube_purpose
    end

    def tube_state?(labware_descendant)
      labware_descendant.state == downstream_seq_tube_state
    end

    def fetch_v2_tube(labware_descendant)
      Sequencescape::Api::V2::Tube.find_all(
        { uuid: labware_descendant.uuid },
        includes: TUBE_INCLUDES
      ).first
    end

    def fetch_v2_tube_request(v2_tube)
      v2_tube.requests_as_source&.first
    end

    def fetch_vtube_req_type(v2_tube_req)
      Array(v2_tube_req).first&.request_type
    end

    def req_type_name_matches?(vtube_req_type)
      vtube_req_type.name == downstream_seq_request_type_name
    end

    def allowed_request_state?(v2_tube_req)
      downstream_seq_tube_request_allowed_states.include?(v2_tube_req.state)
    end
  end
end

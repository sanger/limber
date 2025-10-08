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
  # rubocop:disable Metrics/ClassLength
  class SubmissionPlateDownstreamCompletedPresenter < PlatePresenter
    include Statemachine::Shared

    # Modified version of SubmissionWhenPassed state machine
    state_machine :state, initial: :pending do
      event :take_default_path, human_name: 'Manual Transfer' do
        transition pending: :passed
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :processed_1 do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :processed_2 do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :processed_3 do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :processed_4 do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation

        # We only show the submission options sidebar if we are allowed to create a new submission
        def sidebar_partial
          return 'submission_default' if allow_new_submission?

          'default'
        end
      end

      state :qc_complete, human_name: 'QC Complete' do
        include Statemachine::StateAllowsChildCreation
      end

      state :cancelled do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :failed do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :unknown do
        include Statemachine::StateDoesNotAllowChildCreation
      end
    end

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

    DESCENDANT_TUBE_INCLUDES =
      'receptacle,aliquots,aliquots.request,aliquots.request.request_type,receptacle.requests_as_source.request_type'

    # Overridden from SubmissionBehaviour
    # Check for submission already in progress
    # If not, check that the first sequencing run has completed by checking the downstream tubes
    def allow_new_submission?
      # No more than one submission of a type can be active at time for a given labware.
      # Prevent new submissions if any are currently pending (in progress), as the submission type
      # is currently not available.
      return false if pending_submissions?

      # Next check if any downstream tubes exist matching the requirements (there may be more than one
      # depending on pooling and repeats, we need at least one to have completed the first run)
      downstream_sequenced_tubes = find_downstream_sequenced_tubes

      # If there are no downstream tube(s) yet, we have completed the first run so we cannot create the
      # new submission
      return false if downstream_sequenced_tubes.blank?

      # We found at least one downstream tube matching the requirements so we can allow a new submission
      true
    end

    def pending_submissions?
      submissions.any? do |submission|
        %w[building pending processing].include?(submission.state) ||
          submission.building_in_progress?(ready_buffer: 20.seconds)
      end
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

      return false unless tube_state?(labware_descendant)

      true
    end

    # Check that the tube has a request of the specified type and state
    # Returns true if all checks pass, false otherwise
    def tube_request_matches_requirements?(labware_descendant)
      v2_tube = fetch_v2_tube(labware_descendant)
      return false unless v2_tube

      v2_tube_reqs = fetch_v2_tube_requests(v2_tube)
      return false if v2_tube_reqs.empty?

      # look for a request matching the type and allowed state
      matching_request?(v2_tube_reqs)
    end

    def matching_request?(v2_tube_reqs)
      acceptable_request_found = false
      v2_tube_reqs.each do |v2_tube_req|
        tube_req_type = fetch_tube_req_type(v2_tube_req)

        next unless tube_req_type.present? && req_type_name_matches?(tube_req_type)

        next unless allowed_request_state?(v2_tube_req)

        acceptable_request_found = true
        break
      end

      acceptable_request_found
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
        includes: DESCENDANT_TUBE_INCLUDES
      ).first
    end

    def fetch_v2_tube_requests(v2_tube)
      # may be more than one request as source if they cancelled or failed a tube and repeated
      v2_tube.requests_as_source || []
    end

    def fetch_tube_req_type(v2_tube_req)
      v2_tube_req.request_type.name
    end

    def req_type_name_matches?(tube_req_type)
      tube_req_type == downstream_seq_request_type_name
    end

    def allowed_request_state?(v2_tube_req)
      downstream_seq_tube_request_allowed_states.include?(v2_tube_req.state)
    end

    # Overriden from SubmissionBehaviour
    # Used to decide what suggested child labwares can be created from this labware.
    # Checks the request types of the pipeline filtered suggested child purposes against the incomplete
    # requests on the labware. Only purposes where request_type_key filters match an incomplete submission
    # are returned.
    # def suggested_purpose_options
    #   spo = active_pipelines
    #     .lazy
    #     .filter_map do |pipeline, _store|
    #     child_name = pipeline.child_for(labware.purpose_name)
    #     uuid, settings =
    #       compatible_purposes.detect { |_purpose_uuid, purpose_settings| purpose_settings[:name] == child_name }
    #     next unless uuid

    #     [uuid, settings.merge(filters: pipeline.filters)]
    #   end
    #     .uniq

    #   # Collect all request_type_keys from labware.incomplete_requests
    #   incomplete_request_type_keys = labware.incomplete_requests.filter_map(&:request_type_key)

    #   spo.select do |(_uuid, settings)|
    #     filter_keys = Array(settings[:filters][:request_type_key])
    #     filter_keys.all? { |key| incomplete_request_type_keys.include?(key) }
    #   end
    # end
    def suggested_purpose_options
      spo = build_suggested_purpose_options
      incomplete_request_type_keys = collect_incomplete_request_type_keys
      filter_suggested_purpose_options(spo, incomplete_request_type_keys)
    end

    def build_suggested_purpose_options
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

    def collect_incomplete_request_type_keys
      labware.incomplete_requests.filter_map(&:request_type_key)
    end

    def filter_suggested_purpose_options(spo, incomplete_request_type_keys)
      spo.select do |(_uuid, settings)|
        filter_keys = Array(settings[:filters][:request_type_key])
        filter_keys.all? { |key| incomplete_request_type_keys.include?(key) }
      end
    end
  end

  # rubocop:enable Metrics/ClassLength
end

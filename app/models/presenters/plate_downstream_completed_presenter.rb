# frozen_string_literal: true

module Presenters
  #
  # This Presenter only shows the downstream labware creation button(s) if the specified
  # downstream path has completed.
  # Namely, a downstream tube labware of specified purpose must have a specified
  # state, and must have sequencing requests of the specified type in the specified state.
  #
  # Designed for Ultima where we loop back to perform balancing. But only after
  # the initial sequencing run has been completed.
  #
  class PlateDownstreamCompletedPresenter < PlatePresenter
    include Presenters::Statemachine::Standard

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

    # Not strictly validation, used to display messages relating to the status of downstream runs.
    # Other presenters use a similar pattern.
    validate :ultima_run_status

    private

    # --- parameters from purpose config ---
    def downstream_seq_tube_purpose
      @downstream_seq_tube_purpose ||=
        purpose_config.dig(:presenter_class, :args, :downstream_seq_tube, :purpose)
    end

    def child_tube_purposes
      @child_tube_purposes ||=
        Array(purpose_config.dig(:presenter_class, :args, :child_tube_purposes))
    end
    # --- end parameters from purpose config ---

    def ultima_run_status
      @ultima_run_status ||= find_ultima_run_status

      case @ultima_run_status
      when :unknown
        errors.add(:base, "Unable to determine the status of the downstream sequencing run, so creating child labware of the following types is disabled: #{child_tube_purposes.join(', ')}. Please refresh the page or contact PSD.")
      when :not_finished
        errors.add(:base, "The initial sequencing run is not yet complete, so creating child labware of the following types is disabled: #{child_tube_purposes.join(', ')}.")
      when :finished
        # No error message if finished, as child creation will be allowed and there will be no issue for the user.
      end
    end

    def find_ultima_run_status
      # TODO: replace 'descendants' call with one like 'descendants_with_requests_as_source'
      # to avoid requerying tubes individually in fetch_tube.
      # binding.pry
      downstream_sequenced_tubes = @labware.descendants.all.select{ |d| d.purpose&.name == downstream_seq_tube_purpose }
      return :not_finished if downstream_sequenced_tubes.empty?

      return :finished if Limber::Application.config.mock_ultima_run_check

      # Collect the wafer IDs for all requests coming out of all downstream sequenced tubes
      wafer_ids = downstream_sequenced_tubes.map do |tube|
        fetch_tube(tube)&.requests_as_source&.map(&:id_wafer_lims)
      end.flatten.compact.uniq

      begin
        if mlwh_contains_run_record(wafer_ids)
          return :finished
        else
          return :not_finished
        end
      rescue => e
        Rails.logger.error("Error checking for Useq Wafers with id_wafer_lims in #{wafer_ids}: #{e.message}")
        return :unknown
      end
    end

    def fetch_tube(labware_descendant)
      Sequencescape::Api::V2::Tube.find_all(
        { uuid: labware_descendant.uuid },
        includes: DESCENDANT_TUBE_INCLUDES
      ).first
    end

    # Use sql2 gem as don't need any Rails ORM functionality
    # for this single query to an external database.
    def mlwh_contains_run_record(wafer_ids)
      client = Mysql2::Client.new(
        host: Rails.application.config.mlwh_host,
        username: Rails.application.config.mlwh_username,
        password: Rails.application.config.mlwh_password,
        database: Rails.application.config.mlwh_db
      )

      query_string = "SELECT * FROM useq_wafer WHERE id_wafer_lims IN ('#{wafer_ids.join('\',\'')}')"
      results = client.query(query_string)
      client.close

      results.count > 0
    end

    # Used to decide what suggested child labwares can be created from this labware.
    # Checks the request types of the pipeline filtered suggested child purposes against the incomplete
    # requests on the labware. Only purposes where request_type_key filters match an incomplete submission
    # are returned.
    def suggested_purpose_options
      spo = build_suggested_purpose_options

      # filter out the purpose(s) specified in the purpose config if we cannot allow the child creation yet
      if allow_specific_child_creation?
        spo
      else
        filter_suggested_purpose_options(spo)
      end
    end

    # This identifies possible child purposes based on the active pipelines for this labware
    # and the compatible purposes defined in the configuration files.
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

    # This removes purposes from the suggested list
    # if they are in a list specified in the purpose config.
    def filter_suggested_purpose_options(spo)
      spo.reject do |(_uuid, settings)|
        child_tube_purposes.include?(settings[:name])
      end
    end

    # Prevents the display of specific child creation buttons unless the first sequencing path has finished
    def allow_specific_child_creation?
      ultima_run_status == :finished
    end
  end
end

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
  # rubocop:disable Metrics/ClassLength
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

    # Prevents the display of specific child creation buttons unless the first sequencing path has finished
    def allow_specific_child_creation?
      # TODO: Check MLWH to see if the run has finished.
    end

    private

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

    # This removed purposes from the suggested list
    # if they are in a list specified in the purpose config.
    def filter_suggested_purpose_options(spo)
      spo.reject do |(_uuid, settings)|
        child_tube_purposes.include?(settings[:name])
      end
    end
  end

  # rubocop:enable Metrics/ClassLength
end

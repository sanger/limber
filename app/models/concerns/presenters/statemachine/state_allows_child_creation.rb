# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of child assets in this state
  module StateAllowsChildCreation
    def control_additional_creation
      yield
    end

    def suggested_purposes
      construct_buttons(suggested_purpose_options)
    end

    def compatible_plate_purposes
      construct_buttons(purposes_of_type('plate'))
    end

    def compatible_tube_purposes
      construct_buttons(purposes_of_type('tube'))
    end

    # Eventually this will end up on our labware_creators/creations module
    def purposes_of_type(type)
      compatible_purposes.select do |_uuid, purpose|
        purpose.asset_type == type
      end
    end

    def construct_buttons(scope)
      scope.map do |purpose_uuid, purpose_settings|
        LabwareCreators.class_for(purpose_uuid).creator_button(
          creator: LabwareCreators.class_for(purpose_uuid),
          parent_uuid: uuid,
          parent: labware,
          purpose_uuid: purpose_uuid,
          name: purpose_settings.name,
          type: purpose_settings.asset_type,
          filters: purpose_settings.filters || {}
        )
      end.force
    end

    def active_pipelines
      Settings.pipelines.active_pipelines_for(labware)
    end

    # TODO: Refactor handling of purposes to tidy this up
    def suggested_purpose_options
      active_pipelines.lazy.map do |pipeline, _store|
        child_name = pipeline.child_for(labware.purpose.name)
        uuid, settings = compatible_purposes.detect do |_purpose_uuid, purpose_settings|
          purpose_settings[:name] == child_name
        end
        next unless uuid

        [uuid, settings.merge(filters: pipeline.filters)]
      end.reject(&:nil?).uniq
    end

    def compatible_purposes
      Settings.purposes.lazy.select do |uuid, _purpose_settings|
        LabwareCreators.class_for(uuid).support_parent?(labware)
      end
    end
  end
end

# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of child assets in this state
  module StateAllowsChildCreation
    def control_additional_creation
      yield
      nil
    end

    def compatible_pipeline?(pipelines)
      pipelines.nil? ||
        pipelines.include?(active_request_type)
    end

    def suggested_purposes
      Settings.purposes.each do |uuid, purpose_settings|
        next unless purpose_settings.parents&.include?(labware.purpose.name) &&
                    compatible_pipeline?(purpose_settings.expected_request_types) &&
                    LabwareCreators.class_for(uuid).support_parent?(labware)
        yield uuid, purpose_settings.name, purpose_settings.asset_type
      end
    end

    def compatible_plate_purposes
      purposes_of_type('plate').each do |uuid, hash|
        next unless LabwareCreators.class_for(uuid).support_parent?(labware)
        yield uuid, hash['name']
      end
    end

    def compatible_tube_purposes
      purposes_of_type('tube').each do |uuid, hash|
        next unless LabwareCreators.class_for(uuid).support_parent?(labware)
        yield uuid, hash['name']
      end
    end

    # Eventually this will end up on our labware_creators/creations module
    def purposes_of_type(type)
      Settings.purposes.select do |_uuid, purpose|
        purpose.asset_type == type
      end
    end
  end
end

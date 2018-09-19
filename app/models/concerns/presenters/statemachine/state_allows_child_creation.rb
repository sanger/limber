# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of child assets in this state
  module StateAllowsChildCreation
    def control_additional_creation
      yield
    end

    def compatible_pipeline?(pipelines)
      pipelines.nil? ||
        (pipelines & active_request_types).present?
    end

    def suggested_purposes
      Settings.purposes.each_with_object([]) do |(purpose_uuid, purpose_settings), store|
        next unless  purpose_settings.parents&.include?(labware.purpose.name) &&
                     compatible_pipeline?(purpose_settings.expected_request_types) &&
                     LabwareCreators.class_for(purpose_uuid).support_parent?(labware)

        yield purpose_uuid, purpose_settings.name, purpose_settings.asset_type, purpose_settings.expected_request_types if block_given?
        store << LabwareCreators.class_for(purpose_uuid).creator_button(
          creator: LabwareCreators.class_for(purpose_uuid),
          parent_uuid: uuid,
          parent: labware,
          purpose_uuid: purpose_uuid,
          name: purpose_settings.name,
          type: purpose_settings.asset_type,
          filters: { request_types: purpose_settings.expected_request_types }
        )
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

# frozen_string_literal: true

module Presenters::Statemachine
  # Supports creation of child assets in this state
  module StateAllowsChildCreation
    def control_additional_creation
      yield
    end

    def matching_filters?(purpose_settings)
      purpose_req_types = purpose_settings.expected_request_types
      purpose_lib_types = purpose_settings.expected_library_types
      ((purpose_req_types.nil? || (purpose_req_types & active_request_types).present?) &&
       (purpose_lib_types.nil? || (purpose_lib_types & active_library_types).present?))
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

    def suggested_purpose_options
      compatible_purposes.select do |_purpose_uuid, purpose_settings|
        purpose_settings.parents&.include?(labware.purpose.name) &&
          matching_filters?(purpose_settings)
      end
    end

    def compatible_purposes
      Settings.purposes.lazy.select do |uuid, _purpose_settings|
        LabwareCreators.class_for(uuid).support_parent?(labware)
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
          filters: {
            request_types: purpose_settings.expected_request_types,
            library_types: purpose_settings.expected_library_types
          }
        )
      end.force
    end

    # Eventually this will end up on our labware_creators/creations module
    def purposes_of_type(type)
      compatible_purposes.select do |_uuid, purpose|
        purpose.asset_type == type
      end
    end
  end
end

# frozen_string_literal: true

# Include in a presenter to add support for creating
# child purposes
module Presenters::CreationBehaviour
  def suggested_purposes
    construct_buttons(suggested_purpose_options)
  end

  def compatible_plate_purposes
    construct_buttons(purposes_of_type('plate'))
  end

  def compatible_tube_purposes
    construct_buttons(purposes_of_type('tube'))
  end

  def compatible_tube_rack_purposes
    construct_buttons(purposes_of_type('tube_rack'))
  end

  private

  # Eventually this will end up on our labware_creators/creations module
  def purposes_of_type(type)
    compatible_purposes.select { |_uuid, purpose| purpose.asset_type == type }
  end

  def construct_buttons(scope)
    scope
      .map do |purpose_uuid, purpose_settings|
        LabwareCreators.class_for(purpose_uuid).creator_button(
          creator: LabwareCreators.class_for(purpose_uuid),
          parent_uuid: uuid,
          parent: labware,
          purpose_uuid: purpose_uuid,
          name: purpose_settings[:name],
          type: purpose_settings[:asset_type],
          filters: purpose_settings[:filters] || {}
        )
      end
      .force
  end

  def active_pipelines
    Settings.pipelines.active_pipelines_for(labware)
  end

  # TODO: Refactor handling of purposes to tidy this up
  def suggested_purpose_options
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

  def compatible_purposes
    Settings.purposes.children.lazy.select do |uuid, _purpose_settings|
      LabwareCreators.class_for(uuid).support_parent?(labware)
    end
  end
end

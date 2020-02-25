# frozen_string_literal: true

module SearchHelper
  def stock_plate_uuids
    Settings.purposes.select { |_uuid, config| config.input_plate }.keys
  end

  def self.stock_plate_names
    Settings.purposes.values.select(&:input_plate).map(&:name)
  end

  def self.alternative_workline_reference_name(labware)
    pipelines = Settings.pipelines.active_pipelines_for(labware)
    names = pipelines.map(&:alternative_workline_identifier).compact.uniq
    return nil if names.size > 1

    names.first
  end

  def self.merger_plate_names
    Settings.purposes.values.select(&:merger_plate).map(&:name)
  end

  def purpose_options(type)
    Settings.purposes
            .select { |_uuid, settings| settings[:asset_type] == type }
            .map { |uuid, settings| [settings[:name], uuid] }
  end
end

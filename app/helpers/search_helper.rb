# frozen_string_literal: true

module SearchHelper
  def stock_plate_uuids
    Settings.purposes.select { |_uuid, config| config.input_plate }.keys
  end

  def self.stock_plate_names
    Settings.purposes.values.select(&:input_plate).map(&:name)
  end

  def self.purpose_config_for_purpose_name(purpose_name)
    Settings.purposes.values.select { |obj| obj[:name] == purpose_name }.first
  end

  def self.alternative_workline_reference_name(labware)
    conf = purpose_config_for_purpose_name(labware.purpose.name)
    return nil if conf.nil?

    conf.dig(:alternative_workline_identifier)
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

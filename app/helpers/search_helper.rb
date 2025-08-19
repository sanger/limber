# frozen_string_literal: true

module SearchHelper # rubocop:todo Style/Documentation
  def stock_plate_uuids
    Settings.purposes.children.select { |_uuid, config| config.input_plate }.keys
  end

  def self.stock_plate_names
    Settings.purposes.children.values.select(&:input_plate).map(&:name)
  end

  # Returns purpose names of stock plates using stock_plate flag instead of input_plate.
  def self.stock_plate_names_with_flag
    Settings.purposes.children.values.select(&:stock_plate).map(&:name)
  end

  def self.purpose_config_for_purpose_name(purpose_name)
    Settings.purposes.children.values.find { |obj| obj[:name] == purpose_name }
  end

  def self.alternative_workline_reference_name(labware)
    conf = purpose_config_for_purpose_name(labware.purpose_name)
    return nil if conf.nil?

    conf[:alternative_workline_identifier]
  end

  def self.merger_plate_names
    Settings.purposes.children.values.select(&:merger_plate).map(&:name)
  end

  def purpose_options(type)
    Settings
      .purposes
      .children
      .select { |_uuid, settings| settings[:asset_type] == type }
      .map { |uuid, settings| [settings[:name], uuid] }
  end
end

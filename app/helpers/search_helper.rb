# frozen_string_literal: true

module SearchHelper
  def stock_plate_uuids
    Settings.purposes.select { |_uuid, config| config.input_plate }.keys
  end

  def purpose_options(type)
    Settings.purposes
            .select { |_uuid, settings| settings[:asset_type] == type }
            .map { |uuid, settings| [settings[:name], uuid] }
  end
end

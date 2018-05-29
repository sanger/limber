# frozen_string_literal: true

class Limber::PlatePurpose < Sequencescape::PlatePurpose
  def asset_type
    Settings.purposes.fetch(uuid).asset_type
  end
end

# frozen_string_literal: true

class Limber::PlatePurpose < Sequencescape::PlatePurpose
  def is_qc?
    Settings.qc_purposes.include?(name)
  end

  def not_qc?
    !is_qc?
  end

  def asset_type
    Settings.purposes.fetch(uuid).asset_type
  end
end

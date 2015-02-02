class IlluminaB::PlatePurpose < Sequencescape::PlatePurpose

  def is_qc?
    Settings.qc_purposes.include?(name)
  end

  def not_qc?
    !is_qc?
  end
end

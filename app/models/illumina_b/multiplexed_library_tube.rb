class IlluminaB::MultiplexedLibraryTube < Sequencescape::MultiplexedLibraryTube
  def coerce
    return self
  end

  def location
    'A1'
  end

end

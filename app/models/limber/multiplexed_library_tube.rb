# frozen_string_literal: true

class Limber::MultiplexedLibraryTube < Sequencescape::MultiplexedLibraryTube
  def coerce
    self
  end

  def location
    'A1'
  end

  alias plate_purpose purpose
end

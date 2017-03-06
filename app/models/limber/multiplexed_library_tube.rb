# frozen_string_literal: true

class Limber::MultiplexedLibraryTube < Sequencescape::MultiplexedLibraryTube
  def location
    'A1'
  end

  alias plate_purpose purpose
end

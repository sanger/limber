# frozen_string_literal: true

class Limber::MultiplexedLibraryTube < Sequencescape::MultiplexedLibraryTube
  def location
    'A1'
  end

  alias plate_purpose purpose

  #
  # Override the model used in form/URL helpers
  # to allow us to treat tubes and multiplexed tubes
  # the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Tube
  #
  def model_name
    ::ActiveModel::Name.new(Limber::Tube, false)
  end

  # Mocked out for the time being
  def submissions
    []
  end
end

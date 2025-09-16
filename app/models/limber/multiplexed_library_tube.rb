# frozen_string_literal: true

# API V1 multiplexed library tube, extends the sequencescape-client-api implementation
# to provide API compatibility with the V2 implementation
class Limber::MultiplexedLibraryTube < Sequencescape::MultiplexedLibraryTube
  def location
    'A1'
  end

  alias plate_purpose purpose

  def tube?
    true
  end

  def plate?
    false
  end

  def tube_rack?
    false
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat tubes and multiplexed tubes
  # the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Tube
  #
  def model_name
    ::ActiveModel::Name.new(Tube)
  end

  # Mocked out for the time being
  def in_progress_submission_uuids
    []
  end
end

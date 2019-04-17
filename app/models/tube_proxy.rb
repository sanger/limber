# frozen_string_literal: true

# A tube proxy wraps a tube id and presents it to Rails
# such that it can be used by url helpers
class TubeProxy
  attr_reader :to_param

  #
  # @param id [Integer] The uuid of the tube to redirect to
  def initialize(id)
    @to_param = id
  end

  def to_model
    self
  end

  def model_name
    ::ActiveModel::Name.new(Limber::Tube, false)
  end

  def persisted?
    true
  end
end

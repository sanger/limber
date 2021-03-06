# frozen_string_literal: true

class AssociatedStrategy
  def initialize
    @strategy = FactoryBot.strategy_by_name(:attributes_for).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    attributes = @strategy.result(evaluation)
    attributes.delete(:json_root)
    attributes.delete(:json_render)
    attributes
  end
end

FactoryBot.register_strategy(:associated, AssociatedStrategy)

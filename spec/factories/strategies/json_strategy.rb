# frozen_string_literal: true

class JsonStrategy
  def initialize
    @strategy = FactoryGirl.strategy_by_name(:attributes_for).new
  end

  delegate :association, to: :@strategy

  def result(evaluation)
    JsonRenderer.new_renderer(@strategy.result(evaluation)).to_get_json
  end
end

FactoryGirl.register_strategy(:json, JsonStrategy)

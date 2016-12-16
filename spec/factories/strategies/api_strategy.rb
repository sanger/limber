# frozen_string_literal: true
class ApiStrategy
  attr_reader :api

  def initialize
    @strategy = FactoryGirl.strategy_by_name(:json).new
    @api = Sequencescape::Api.new(
      url: 'http://example.com:3000/', cookie: nil,
      namespace: Limber, authorisation: 'testing'
    )
  end

  delegate :association, to: :@strategy

  def result(evaluation)
  end
end

FactoryGirl.register_strategy(:api_object, ApiStrategy)

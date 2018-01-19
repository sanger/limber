# frozen_string_literal: true

require_relative '../support/json_renderers'

FactoryGirl.define do
  factory :submission_template, class: Sequencescape::OrderTemplate, traits: %i[api_object] do
    json_root 'order_template'
    name 'Submission Template'
    with_has_many_associations 'orders', actions: ['create']
  end
end

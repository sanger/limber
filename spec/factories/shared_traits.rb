
# frozen_string_literal: true
require_relative '../support/json_renderers'

FactoryGirl.define do
  trait :api_object do
    transient do
      api_root 'http://localhost:3000/'

      api do
        Sequencescape::Api.new(
          url: api_root, cookie: nil,
          namespace: Limber, authorisation: 'testing'
        )
      end

      resource_actions ['read']
      named_actions []
      resource_url  { api_root + uuid }
    end

    json_render JsonRenderer
    json_root 'please define on factory'
    uuid { SecureRandom.uuid }

    actions do
      action = Hash[resource_actions.map { |action_name| [action_name, resource_url] }]
      action.merge Hash[named_actions.map { |action_name| [action_name, resource_url + '/' + action_name] }]
    end

    initialize_with do
      new(api, json_render.new(json_root, attributes).to_hash)
    end
  end
end


require_relative '../support/json_renderers'

FactoryGirl.define do
  trait :api_object do

    transient do
      api do
        Sequencescape::Api.new(
          url: 'http://localhost:3000/', cookie: nil,
          namespace: Limber, authorisation: 'testing'
        )
      end

    end

    json_render JsonRenderer
    json_root 'please define on factory'

    initialize_with do
      new(api,json_render.new(json_root,attributes).to_hash)
    end
  end
end

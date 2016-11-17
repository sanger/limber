# frozen_string_literal: true
module ApiUrlHelper
  API_ROOT = 'http://localhost:3000/'

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def api_root
      API_ROOT
    end

    def api_url_for(model, association)
      uuid = model.is_a?(String) ? model : model.uuid
      "#{api_root}#{uuid}/#{association}"
    end
  end
end

RSpec.configure do |config|
  config.include ApiUrlHelper
end

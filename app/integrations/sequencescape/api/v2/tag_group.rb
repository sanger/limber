# frozen_string_literal: true

# Tag groups contain lists of tags
class Sequencescape::Api::V2::TagGroup < Sequencescape::Api::V2::Base
  has_one :tag_group_adapter_type, class_name: 'Sequencescape::Api::V2::TagGroupAdapterType'
end

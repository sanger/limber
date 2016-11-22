# frozen_string_literal: true
class JsonRenderer
  def self.new_renderer(attributes)
    attrs = attributes
    renderer = attrs.delete(:json_render) || JsonRenderer
    root = attrs.delete(:json_root)
    renderer.new(root, attrs)
  end

  def initialize(root, attributes)
    @root = root
    @attributes = attributes.stringify_keys
  end

  def to_hash
    @attributes
  end

  def to_get_json
    { @root => to_hash }.to_json
  end
end

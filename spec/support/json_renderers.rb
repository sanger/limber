# frozen_string_literal: true

class JsonRenderer
  # Returns a new json renderer based on the Factory Girl output
  #
  # @param [Type] attributes describe attributes as output by factory girl. Includes json_render: custom render class,
  # json_root: The root of the generated json. Usually matches the endpoint. Set to nil to surpress the root.
  # @return [JsonRenderer] A new JsonRenderer
  def self.new_renderer(attributes)
    attrs = attributes
    renderer = attrs.delete(:json_render) || JsonRenderer
    root = attrs.delete(:json_root)
    renderer.new(root, attrs)
  end

  # Create a new json render. Suppressing the root is useful for rendering json arrays.
  #
  # @param [String] root The root of the generated json. Usually matches the endpoint. Set to nil to surpress the root.
  # @param [Hash] attributes Attributes to be serialized
  # @return [JsonRenderer] A new JsonRenderer
  def initialize(root, attributes)
    @root = root
    @attributes = attributes.stringify_keys
  end

  def to_hash
    @attributes
  end

  # The json expected from a GET request to the resource
  def to_get_json
    if @root.nil?
      to_hash.to_json
    else
      { @root => to_hash }.to_json
    end
  end
end

# frozen_string_literal: true

# Parent configuration mixin.
module ConfigurationV2
  # Configuration for the application, including loaders for various configurations.

  def initialize(config_hash)
    # config_hash.with_indifferent_access.each do |key, value|
    # end
  end

  # Configuration item.
  class Item
    include Enumerable

    attr_reader :children, :configuration

    # rubocop:disable Metrics/MethodLength
    def initialize(configuration, children = {})
      @children = children
      @configuration = configuration

      children.each do |key, child|
        if child.is_a?(ActiveSupport::HashWithIndifferentAccess)
          next if respond_to?(key)

          child_item = Item.new(configuration, child)
          define_singleton_method(key) { child_item }
        else
          define_singleton_method(key) { child }
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    def each(...)
      children.each(...)
    end
  end
end

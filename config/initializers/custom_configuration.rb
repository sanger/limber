# frozen_string_literal: true

# Parent configuration mixin.
module Settings
  # Configuration for the application, including loaders for various configurations.

  # This will create class-level functions so that they could be accessed like
  # Settings.searches, Settings.transfer_templates, etc.
  class CustomConfiguration
    def initialize(config_hash)
      @children = config_hash.with_indifferent_access

      # When you invoke, Settings.configuration.searches in settings.rb, it would invoke static
      # methods declared through this block.
      @children.each do |key, value|
        # For every getter method, it creates a method that returns an Item instance
        # with the key and value from the configuration hash.
        define_singleton_method(key) { Item.new(key, value) }
        # For every setter method, it creates a method that sets the value in the children hash.
        # This allows you to do Settings.configuration.searches = new_value.
        define_singleton_method("#{key}=") { |new_value| @children[key] = new_value }
      end
    end

    # Configuration item. It recursively builds a structure
    # that allows for nested configurations to be accessed easily.
    # It includes Enumerable to allow iteration over its children.
    #
    # Each child can be a nested configuration or a simple value.
    # This allows for a flexible and dynamic configuration structure.
    #
    # @example
    #   config = Settings.configuration
    #   config.searches.some_child.some_grandchild
    #   config.searches.some_child.some_grandchild = new_value
    #
    class Item
      include Enumerable

      attr_reader :children, :configuration

      # rubocop:disable Metrics/MethodLength
      def initialize(configuration, children = {})
        @children = children
        @configuration = configuration

        # Dynamically defines getter and setter methods for each child key in the configuration.
        #
        # For each key-value pair in the children hash:
        # - If the value is a nested hash (ActiveSupport::HashWithIndifferentAccess),
        #   it creates a getter method that returns a new Item instance, allowing for recursive access.
        # - If the value is a simple value, it creates a getter method that returns the value directly.
        # - For every key, it also creates a setter method to update the value in the children hash.
        #
        # This enables flexible, dot-notation access and assignment for deeply nested configuration structures.
        #
        # Example:
        #   config = Settings.configuration
        #   config.searches.some_child.some_grandchild        # Access nested value
        #   config.searches.some_child.some_grandchild = val  # Set nested value
        children.each do |key, child|
          if child.is_a?(ActiveSupport::HashWithIndifferentAccess)
            next if respond_to?(key)

            child_item = Item.new(configuration, child)
            define_singleton_method(key) { child_item }
          else
            define_singleton_method(key) { child }
          end
          define_singleton_method("#{key}=") { |new_value| @children[key] = new_value }
        end
      end
      # rubocop:enable Metrics/MethodLength

      delegate :[]=, to: :@children

      def fetch(key, default = nil)
        @children.fetch(key, default)
      end

      def each(...)
        children.each(...)
      end
    end
  end
end

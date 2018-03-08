# frozen_string_literal: true

module LabwareCreators::Tagging
  #
  # Class Tag2Collection provides a list of tag 2 templates available for a given plate.
  class Tag2Collection
    #
    # Create a tag collection
    #
    # @param [Sequencescape::Client::Api] an api object used to retrieve tag 2 templates
    # @param [Limber::Plate] The plate from which to filter out used templates
    #
    def initialize(api, plate)
      @api = api
      @plate = plate
    end

    #
    # Returns a list of tag2 layouts compatible with the given plate
    #
    #
    # @return [Hash] A hash of template uuids as keys, and simple summary as values
    #
    def list
      @list ||= all_templates.each_with_object({}) do |template, hash|
        hash[template.uuid] = {
          dual_index: true,
          used: used.include?(template.uuid)
        }
      end
    end

    def used
      return [] if @plate.submission_pools.empty?
      @used ||= @plate.submission_pools.each_with_object(Set.new) do |pool, set|
        pool.used_tag2_layout_templates.each { |used| set << used['uuid'] }
      end
    end

    #
    # Indicates that a tag2 tube has been used in the pool
    #
    # @return [Boolean] Returns true if a tag2 tube has been used in any pool. False otherwise.
    def used?
      used.present?
    end

    #
    # Return an array of available template names
    #
    # @return [Array<String>] A list of available templates
    def names
      available_templates.map(&:name)
    end

    private

    def all_templates
      @all_templates ||= @api.tag2_layout_template.all
    end

    def available_templates
      @available_templates ||= all_templates.reject do |template|
        used.include?(template.uuid)
      end
    end
  end
end

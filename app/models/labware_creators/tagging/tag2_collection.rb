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
    # @return [Hash] A hash of template uuids as keys, and the templates themselves as values.
    #
    def available
      @api.tag2_layout_template.all.reject do |template|
        used.include?(template.uuid)
      end.index_by(&:uuid)
    end

    def used
      @used ||= @plate.submission_pools.each_with_object(Set.new) do |pool, set|
        pool.used_tag2_layout_templates.each { |used| set << used['uuid'] }
      end
    end
  end
end

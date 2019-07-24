# frozen_string_literal: true

module LabwareCreators::Tagging
  class TagCollection
    #
    # Create a tag collection
    #
    # @param [Sequencescape::Client::Api] api an api object used to retrieve tag 2 templates
    # @param [Limber::Plate] plate The plate from which the tag layout will be generated
    # @param [String] purpose_uuid The uuid of the purpose which is about to be created
    #
    def initialize(api, plate, purpose_uuid)
      @api = api
      @plate = plate
      @purpose_uuid = purpose_uuid
    end

    #
    # Returns hash of usable tag layout templates, and the tags assigned to
    # each well:
    # eg. { "tag-layout-template-0"=>{tags: [["A1", [1, 1]], ["B1", [1, 2]]], dual_index: true } }
    # where { tag_template_uuid => { tags: [[well_name, [ pool_id, tag_id ]]], dual_index: dual_index? } }
    # @return [Hash] Tag layouts and their tags
    #
    def list
      @list ||= tag_layout_templates.each_with_object({}) do |layout, hash|
        catch(:unacceptable_tag_layout) do
          hash[layout.uuid] = {
            tags: tags_by_column(layout),
            dual_index: layout.dual_index?,
            used: used.include?(layout.uuid),
            approved: acceptable_template?(layout)
          }
        end
      end
    end

    def used
      return [] if @plate.submission_pools.empty?

      @used ||= @plate.submission_pools.each_with_object(Set.new) do |pool, set|
        pool.used_tag_layout_templates.each { |used| set << used['uuid'] }
      end
    end

    def used?
      used.present?
    end

    private

    #
    # Returns the accepted tag layouts for the target plate purpose
    # Returns nil if no templates are specified.
    # Generally nil indicates that all templates are acceptable.
    #
    # @return [<type>] <description>
    #
    def acceptable_templates
      Settings.purposes.dig(@purpose_uuid, 'tag_layout_templates')
    end

    #
    # Returns true if the given template is in the approved list
    # or the approved list is empty. Returns false otherwise.
    #
    # @param [Limber::TagLayoutTemplate] template The template to check
    #
    # @return [Bool] true if the template is acceptable
    #
    def acceptable_template?(template)
      acceptable_templates.blank? ||
        acceptable_templates.include?(template.name)
    end

    def tags_by_column(layout)
      swl = layout.generate_tag_layout(@plate)
      swl.to_a.sort_by { |well, _pool_info| WellHelpers.index_of(well, @plate.size) }
    end

    def tag_layout_templates
      @api.tag_layout_template.all.map(&:coerce)
    end
  end
end

# frozen_string_literal: true

module LabwareCreators::Tagging
  class TagCollection # rubocop:todo Style/Documentation
    # Create a tag collection
    #
    # @param plate [Plate] The plate from which the tag layout will be generated
    # @param purpose_uuid [String] The uuid of the purpose which is about to be created
    def initialize(plate, purpose_uuid)
      @plate = plate
      @purpose_uuid = purpose_uuid
    end

    # Returns hash of usable tag layout templates, and the tags assigned to each well:
    # eg. { "tag-layout-template-0" => { tags: [["A1", [1, 1]], ["B1", [1, 2]]], dual_index: true } }
    # where { tag_template_uuid => { tags: [[well_name, [ pool_id, tag_id ]]], dual_index: dual_index? } }
    # @return [Hash] Tag layouts and their tags
    def list
      @list ||=
        tag_layout_templates.each_with_object({}) do |layout, hash|
          # the `throw` that this catches comes from `generate_tag_layout` method
          catch(:unacceptable_tag_layout) { hash[layout.uuid] = layout_hash(layout) }
        end
    end

    # Builds a hash describing a tag layout template.
    #
    # @param layout [TagLayoutTemplate] The tag layout template.
    # @return [Hash] Information about the template.
    def layout_hash(layout)
      {
        tags: tags_by_column(layout),
        dual_index: layout.dual_index?,
        used: used.include?(layout.uuid),
        matches_templates_in_pool: matches_templates_in_pool(layout.uuid),
        approved: acceptable_template?(layout)
      }
    end

    # Returns a list of the tag layout templates (their uuids) that have already been used on
    # other plates in the relevant submission pools.
    #
    # @return [Array<String>] Used tag layout template UUIDs.
    def used
      return [] if @plate.submission_pools.empty?

      @used ||=
        @plate
          .submission_pools
          .each_with_object(Set.new) { |pool, set| pool.tag_layout_templates.each { |tlt| set << tlt.uuid } }
    end

    # Have any tag layout templates already been used on other plates in the relevant submission pools?
    #
    # @return [Boolean] True if any templates have been used, false otherwise.
    def used?
      used.present?
    end

    # Used where the wells being pooled together originate from the same sample,
    # so should have the same tags, so they are kept together when analysing sequencing data.
    # (As opposed to when the pool will contain multiple samples, and therefore need to have different tags)
    #
    # @param uuid [String] The uuid of the Tag Layout Template we are currently dealing with
    # @return [Boolean] true if either no other templates have been used in the submission pool, or
    #                   if all the templates used are the same as this one
    def matches_templates_in_pool(uuid)
      # if there haven't been any templates used yet in the pool, we say it matches them
      return true if used.empty?

      # return true if this template has been used already in the pool
      used.include?(uuid)
    end

    private

    # Returns the accepted tag layouts for the target plate purpose.
    # Returns nil if no templates are specified.
    # Generally nil indicates that all templates are acceptable.
    #
    # @return [Array<String>, nil] List of acceptable template names, or nil.
    def acceptable_templates
      Settings.purposes.dig(@purpose_uuid, 'tag_layout_templates')
    end

    # Returns true if the given template is in the approved list
    # or the approved list is empty. Returns false otherwise.
    #
    # @param template [Sequencescape::Api::V2::TagLayoutTemplate] The template to check
    # @return [Boolean] true if the template is acceptable
    def acceptable_template?(template)
      acceptable_templates.blank? || acceptable_templates.include?(template.name)
    end

    # Returns an array of wells and their tag assignments, sorted by column.
    #
    # @param layout [TagLayoutTemplate] The tag layout template.
    # @return [Array<Array>] Array of [well_name, pool_info] pairs.
    def tags_by_column(layout)
      swl = layout.generate_tag_layout(@plate)
      swl.to_a.sort_by { |well, _pool_info| WellHelpers.index_of(well, @plate.size) }
    end

    # Returns all tag layout templates available via the API.
    #
    # @return [Array<TagLayoutTemplate>] Array of tag layout templates.
    def tag_layout_templates
      query = Sequencescape::Api::V2::TagLayoutTemplate.paginate(per_page: 100)
      Sequencescape::Api::V2.merge_page_results(query).map(&:coerce)
    end
  end
end

# frozen_string_literal: true

module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    self.page = 'tagging'
    self.attributes = %i[
      api purpose_uuid parent_uuid user_uuid
      tag_plate_barcode tag_plate
      tag2_tube_barcode tag2_tube
    ]

    validates :api, :purpose_uuid, :parent_uuid, :user_uuid, :tag_plate_barcode, :tag_plate, presence: true
    validates :tag2_tube_barcode, :tag2_tube, presence: { if: :requires_tag2? }

    def valid_qcable_information
      tag_plate.present? && tag_plate.valid?
    end

    attr_reader :plate_conversion

    QcableObject = Struct.new(:asset_uuid, :template_uuid)

    def tag_plate=(params)
      return nil if params.blank?
      @tag_plate = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def tag2_tube=(params)
      return nil if params.blank?
      @tag2_tube = QcableObject.new(params[:asset_uuid], params[:template_uuid])
    end

    def initialize(*args, &block)
      super
      plate.populate_wells_with_pool
    end

    def substitutions
      @substitutions ||= {}
    end

    def acceptable_template?(template)
      acceptable_templates.blank? ||
        acceptable_templates.include?(template.name)
    end

    def acceptable_templates
      Settings.purposes[purpose_uuid].fetch('tag_layout_templates', [])
    end

    def tag_groups
      @tag_groups ||= generate_tag_groups
    end

    def tag2s
      @tag2s ||= available_tag2s
    end

    def tag2_names
      tag2s.values.map(&:name)
    end

    def child
      plate_conversion.try(:target) || :child_not_created
    end

    def create_plate!(selected_transfer_template_uuid = default_transfer_template_uuid)
      api.transfer_template.find(selected_transfer_template_uuid).create!(
        source: parent_uuid,
        destination: tag_plate.asset_uuid,
        user: user_uuid
      )

      yield(tag_plate.asset_uuid) if block_given?

      api.state_change.create!(
        user: user_uuid,
        target: tag_plate.asset_uuid,
        reason: 'Used in Library creation',
        target_state: 'exhausted'
      )

      # Convert plate instead of creating it
      @plate_conversion = api.plate_conversion.create!(
        target: tag_plate.asset_uuid,
        purpose: purpose_uuid,
        user: user_uuid,
        parent: parent_uuid
      )

      true
    end

    def requires_tag2?
      plate.submission_pools.detect { |pool| pool.plates_in_submission > 1 }.present?
    end

    def tag2_field
      yield if requires_tag2?
      nil
    end

    private

    def create_labware!
      create_plate! do |plate_uuid|
        api.tag_layout_template.find(tag_plate.template_uuid).create!(
          plate: plate_uuid,
          user: user_uuid,
          substitutions: substitutions.reject { |_, new_tag| new_tag.blank? }
        )

        if tag2_tube_barcode.present?
          api.state_change.create!(
            user: user_uuid,
            target: tag2_tube.asset_uuid,
            reason: 'Used in Library creation',
            target_state: 'exhausted'
          )

          api.tag2_layout_template.find(tag2_tube.template_uuid).create!(
            source: tag2_tube.asset_uuid,
            plate: plate_uuid,
            user: user_uuid
          )
        end
      end
    end

    def tags_by_column(layout)
      swl = layout.generate_tag_layout(plate)
      swl.to_a.sort_by { |well, _pool_info| WellHelpers.index_of(well) }
    end

    def available_tag2s
      api.tag2_layout_template.all.reject do |template|
        used_tag2s.include?(template.uuid)
      end.index_by(&:uuid)
    end

    def used_tag2s
      @used_tag2s ||= plate.submission_pools.each_with_object(Set.new) do |pool, set|
        pool.used_tag2_layout_templates.each { |used| set << used['uuid'] }
      end
    end

    def tag_layout_templates
      api.tag_layout_template.all.map(&:coerce).select do |template|
        acceptable_template?(template) &&
          template.tag_group.tags.size >= maximum_pool_size
      end
    end

    def generate_tag_groups
      tag_layout_templates.each_with_object({}) do |layout, hash|
        catch(:unacceptable_tag_layout) { hash[layout.uuid] = tags_by_column(layout) }
      end
    end

    def maximum_pool_size
      @maximum_pool_size ||= plate.pools.map(&:last).map { |pool| pool['wells'].size }.max || 0
    end
  end
end

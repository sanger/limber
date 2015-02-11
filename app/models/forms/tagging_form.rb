#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014 Genome Research Ltd.
module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'tagging'
    write_inheritable_attribute :attributes, [:api, :purpose_uuid, :parent_uuid, :tag_layout_template_uuid, :user_uuid, :substitutions, :tag_plate_uuid, :tag_plate_barcode]

    validates_presence_of *(self.attributes - [:substitutions])

    attr_reader :plate_conversion

    def initialize(*args, &block)
      super
      plate.populate_wells_with_pool
    end

    def substitutions
      @substitutions ||= {}
    end

    def generate_layouts_and_groups
      maximum_pool_size = plate.pools.map(&:last).map { |pool| pool['wells'].size }.max

      @tag_layout_templates = api.tag_layout_template.all.map(&:coerce).select { |template|
        template.tag_group.tags.size >= maximum_pool_size
      }

      @tag_groups = Hash[
        tag_layout_templates.map do |layout|
          catch(:unacceptable_tag_layout) { [ layout.uuid, tags_by_row(layout) ] }
        end.compact
      ]

      @tag_layout_templates.delete_if { |template| not @tag_groups.key?(template.name) }
    end
    private :generate_layouts_and_groups

    def tag_layout_templates
      generate_layouts_and_groups unless @tag_layout_templates.present?
      @tag_layout_templates
    end

    def tag_groups
      generate_layouts_and_groups unless @tag_groups.present?
      @tag_groups
    end

    def tags_by_name
      @tags_by_name ||=
        Hash[
          tag_layout_templates.map do |layout|
            catch(:unacceptable_tag_layout) { [ layout.name, layout.tag_group.tags.keys.map(&:to_i).sort ] }
          end
        ]
    end

    # Creates a 96 element array of tags from the tag array passed in.
    # If the input is longer than 96 it takes the first 96 if shorter
    # it loops the elements to make up the 96.
    def first_96_tags(tags)
      Array.new(96) { |i| tags[(i % tags.size)] }
    end

    def structured_well_locations(&block)
      Hash.new.tap do |ordered_wells|
        ('A'..'H').each do |row|
          (1..12).each do |column|
            ordered_wells["#{row}#{column}"] = nil
          end
        end
        yield(ordered_wells)
        ordered_wells.delete_if { |_,v| v.nil? }
      end
    end
    private :structured_well_locations

    def tags_by_row(layout)
      structured_well_locations { |tagged_wells| layout.generate_tag_layout(plate, tagged_wells) }.to_a
    end
    private :tags_by_row

    def child
      plate_conversion.try(:target) || :child_not_created
    end

    def create_plate!(selected_transfer_template_uuid = default_transfer_template_uuid, &block)

      api.state_change.create!(
        :user => user_uuid,
        :target => tag_plate_uuid,
        :reason => 'Used in Library creation',
        :target_state => 'exhausted'
      )

      # Convert plate instead of creating it
      @plate_conversion = api.plate_conversion.create!(
        :target => tag_plate_uuid,
        :purpose => purpose_uuid,
        :user => user_uuid,
        :parent => parent_uuid
      )

      api.transfer_template.find(selected_transfer_template_uuid).create!(
        :source      => parent_uuid,
        :destination => tag_plate_uuid,
        :user        => user_uuid
      )

      yield(@plate_conversion.target) if block_given?
      true
    end

    def create_objects!
      create_plate! do |plate|
        api.tag_layout_template.find(tag_layout_template_uuid).create!(
          :plate => plate.uuid,
          :user  => user_uuid,
          :substitutions => substitutions.reject { |_,new_tag| new_tag.blank? }
        )
      end
    end
    private :create_objects!
  end
end

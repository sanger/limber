module Forms
  class TaggingForm < CreationForm
    include Forms::Form::CustomPage

    write_inheritable_attribute :page, 'tagging'
    write_inheritable_attribute :attributes, [:api, :plate_purpose_uuid, :parent_uuid, :tag_layout_template_uuid, :user_uuid, :substitutions]

    validates_presence_of *self.attributes

    def substitutions
      @substitutions ||= {}
    end

    def generate_layouts_and_groups
      maximum_pool_size = plate.pools.map(&:last).map!(&:size).max

      @tag_layout_templates = api.tag_layout_template.all.select do |template|
        template.tag_group.tags.size >= maximum_pool_size
      end

      @tag_groups = Hash[
        tag_layout_templates.map do |layout|
          catch(:unacceptable_tag_layout) { [ layout.name, tags_by_row(layout) ] }
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

    def tag_ids(layout)
      layout.tag_group.tags.keys.map!(&:to_i).sort
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

    def group_wells_of_plate_in_columns
      well_to_pool = {}
      plate.pools.each do |pool_id, wells|
        wells.each { |well| well_to_pool[well] = pool_id }
      end

      (1..12).map do |column|
        [].tap do |wells|
          ('A'..'H').each { |row| wells.push([ "#{row}#{column}", well_to_pool["#{row}#{column}"] ]) }
        end
      end
    end
    private :group_wells_of_plate_in_columns

    def group_wells_of_plate_in_rows
      well_to_pool = {}
      plate.pools.each do |pool_id, wells|
        wells.each { |well| well_to_pool[well] = pool_id }
      end

      ('A'..'H').map do |row|
        [].tap do |wells|
          (1..12).each { |column| wells.push([ "#{row}#{column}", well_to_pool["#{row}#{column}"] ]) }
        end
      end
    end
    private :group_wells_of_plate_in_rows

    def tags_by_row(layout)
      structured_well_locations do |tagged_wells|
        tags, groups = tag_ids(layout), send(:"group_wells_of_plate_in_#{layout.direction.pluralize}")
        pools = groups.map { |pool| pool.map(&:last) }.flatten.uniq
        groups.each_with_index do |current_group, group|
          if group > 0
            prior_group = groups[group-1]

            current_group.each_with_index do |(well,pool_id), index|
              break if prior_group.size <= index
              next if prior_group[index].last != pool_id
              current_group.push([ well, pool_id ])
              current_group[index] = [nil, pool_id]
            end
          end

          current_group.each_with_index do |(well, pool_id), index|
            throw :unacceptable_tag_layout if tags.size <= index
            tagged_wells[well] = [ pools.index(pool_id)+1, tags[index] ] unless well.nil?
          end
        end
      end.to_a
    end
    private :tags_by_row

    def create_objects!
      create_plate! do |plate|
        api.tag_layout_template.find(tag_layout_template_uuid).create!(
          :plate => plate.uuid,
          :user  => user_uuid,
          :substitutions => substitutions.reject! { |_,new_tag| new_tag.blank? }
        )
      end
    end
    private :create_objects!
  end
end

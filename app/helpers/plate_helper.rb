# frozen_string_literal: true

module PlateHelper
  class WellFailingPresenter < BasicObject
    def initialize(form, presenter)
      @form = form
      @presenter = presenter
    end

    def respond_to?(name, include_private = false)
      super || @presenter.respond_to?(name, include_private)
    end

    def method_missing(name, *args, &block)
      @presenter.send(name, *args, &block)
    end
    protected :method_missing

    def aliquot_partial
      'well_failing_aliquot'
    end

    attr_reader :form
  end

  def fail_wells_presenter_from(form, presenter)
    WellFailingPresenter.new(form, presenter)
  end

  def insert_size_class(pool)
    pool['insert_size']['from'] > Settings.large_insert_limit ? 'large-insert-size' : ''
  end

  # Altered to sort by column first then row
  def sortable_well_location_for(location)
    match = location.match(/^([A-Z])(\d+)$/)
    [match[2].to_i, match[1]]
  end
  private :sortable_well_location_for

  def sorted_pre_cap_group_json
    failed_wells = current_plate.wells.select { |w| %w[failed unknown].include?(w.state) }.map(&:location)

    sorted_group_array = current_plate.pre_cap_groups.map do |group_id, group|
      [group_id, group].tap do
        group['failures']  = group['wells'] & failed_wells
        group['all_wells'] = group['wells'].sort_by { |w| WellHelpers.index_of(w) }
        group['wells']     = group['all_wells'] - group['failures']
      end
    end.sort_by do |(_, group)|
      sortable_well_location_for(group['wells'].first || group['all_wells'].first)
    end

    Hash[sorted_group_array].to_json.html_safe
  end

  def current_plate
    (@creation_form || @presenter).labware
  end
end

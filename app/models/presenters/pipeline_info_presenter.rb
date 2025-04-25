# frozen_string_literal: true

# This presenter is used to show the pipeline context for a labware item.
# It shows the appropriate pipeline name, along with the path through the
# pipeline that that particular labware has come, and the potential child
# purposes that it could continue as.
class Presenters::PipelineInfoPresenter
  include Presenters::CreationBehaviour

  attr_reader :labware

  # redirect presenter methods to the labware
  delegate :uuid, to: :labware

  # Initializes the presenter with the given labware.
  #
  # @param labware [Labware] The labware item to present.
  def initialize(labware)
    @labware = labware
  end

  def pipeline_names
    if pipeline_groups_by_filter.empty?
      # if there are no active pipelines, return the pipeline groups by purpose
      return join_up_to(3, pipeline_groups_by_purpose.sort)
    end
    if pipeline_groups_by_purpose.intersect?(pipeline_groups_by_filter)
      # combine the two arrays to find the common pipeline groups
      return join_up_to(3, (pipeline_groups_by_purpose & pipeline_groups_by_filter).sort)
    end
    'No Pipelines Found'
  end

  # Returns true if the labware purpose has any defined parent of grand-parent relationships, false otherwise.
  # return [Boolean] True if the labware has great-grandparent purposes
  def great_grandparent_purposes?
    @labware.parents.any? do |parent|
      labware_from_asset(parent).parents.any? { |grandparent| labware_from_asset(grandparent).parents.any? }
    end
  end

  # Returns a comma-separated list of the purposes of the labware's grandparents.
  # If the labware has no grandparents, it returns an empty string.
  # @return [String] Comma-separated list of grandparent purposes.
  def grandparent_purposes
    @labware
      .parents
      .map { |parent| labware_from_asset(parent).parents.map { |grandparent| grandparent.purpose.name } }
      .flatten
      .uniq
      .join(', ')
  end

  # Returns a comma-separated list of the purposes of the labware's parents.
  # If the labware has no parents, it returns an empty string.
  # @return [String] Comma-separated list of parent purposes.
  def parent_purposes
    @labware.parents.map { |parent| parent.purpose.name }.uniq.join(', ')
  end

  # Returns a comma-separated list of potential child purposes for the labware.
  # If the labware is the last in the pipeline, it returns an empty string.
  # @return [String] Comma-separated list of child purposes
  def child_purposes
    suggested_purposes.map(&:name).uniq.join(', ')
  end

  # Returns true if the labware purpose has any defined child of child relationships, false otherwise.
  # return [Boolean] True if the labware has grandchild purposes
  def grandchild_purposes?
    true
  end

  private

  def pipeline_groups_by_purpose
    Settings
      .pipelines
      .select_pipelines_with_purpose(Settings.pipelines.list, @labware.purpose)
      .map(&:pipeline_group)
      .uniq
  end

  def join_up_to(max_listed, array, separator = ', ')
    return array.join(separator) if array.size <= max_listed

    "#{array[0..max_listed - 1].join(separator)}, ...(#{array.size - max_listed} more)"
  end

  def pipeline_groups_by_filter
    Settings.pipelines.active_pipelines_for(@labware).map(&:pipeline_group).uniq
  end

  def find_plate(barcode)
    Sequencescape::Api::V2::Plate.find_all({ barcode: [barcode] }).first
  end

  def find_tube(barcode)
    Sequencescape::Api::V2::Tube.find_all({ barcode: [barcode] }).first
  end

  def labware_from_asset(asset)
    return find_plate(asset.barcode) if asset.plate?
    return find_tube(asset.barcode) if asset.tube?
    nil
  end
end

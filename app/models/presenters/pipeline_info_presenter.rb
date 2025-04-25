# frozen_string_literal: true

# This presenter is used to show the pipeline context for a labware item.
# It provides methods to retrieve the parents, children, and their purposes,
# as well as the pipeline names associated with the labware's purpose.
class Presenters::PipelineInfoPresenter
  attr_reader :labware

  # Initializes the presenter with the given labware.
  #
  # @param labware [Labware] The labware item to present.
  def initialize(labware)
    @labware = labware
  end

  def pipeline_names
    Settings
      .pipelines
      .select_pipelines_with_purpose(Settings.pipelines.list, @labware.purpose)
      .map(&:pipeline_group)
      .uniq
      .join(', ')
  end

  def parents
    @labware.parents&.filter { |parent| parent.purpose.present? } || []
  end

  def children
    @labware.children&.filter { |child| child.purpose.present? } || []
  end

  def grandparents
    @labware.parents&.filter { |grandparent| grandparent.purpose.present? } || []
  end

  def grandchildren
    @labware.children&.filter { |child| child.purpose.present? } || []
  end

  def previous_purposes
    @labware.parents.map { |parent| parent.purpose.name }.uniq.join(', ')
  end

  def next_purposes
    @labware.children.map { |child| child.purpose.name }.uniq.join(', ')
  end
end

# frozen_string_literal: true

# Controller for visualizing a single labware's pipeline workflow
class PipelineVisualiserController < ApplicationController
  def show
    barcode = params[:id]
    @labware = retrieve_labware_by_barcode(barcode) if barcode.present?
    @labware_data = { record: @labware, state: decide_state(@labware) } if @labware

    respond_to do |format|
      format.html
      format.json { render_graph_json(barcode) }
    end
  end

  private

  def render_graph_json(barcode)
    if barcode.blank?
      render json: { graph_data: { elements: [] } }
    elsif @labware
      render json: { graph_data: labware_to_cytoscape_graph(@labware) }
    else
      render json: { error: 'Labware not found' }, status: :not_found
    end
  end

  # Looks up the labware entered in the barcode search box, with its
  # parents/children associations loaded so the graph can be walked.
  #
  # @param barcode [String] the barcode entered in the search box
  # @return [Sequencescape::Api::V2::Labware, nil] the matching labware,
  #   or nil if not found
  def retrieve_labware_by_barcode(barcode)
    labware_query.where(barcode:).first
  end

  # Looks up a parent/child found while walking the graph, by its uuid, with
  # its own parents/children associations loaded so the walk can continue to
  # build relatives.
  #
  # @param uuid [String] the uuid of the parent/child labware
  # @return [Sequencescape::Api::V2::Labware, nil] the matching labware,
  #   or nil if not found
  def retrieve_labware_by_uuid(uuid)
    labware_query.where(uuid:).first
  end

  # Base query selecting the fields needed to build the graph and walk
  # parents/children, without yet filtering to a specific piece of labware.
  #
  # @return [JsonApiClient::Query::Builder] an unfiltered query,
  #   ready to be filtered by barcode or uuid
  def labware_query
    Sequencescape::Api::V2::Labware
      .select(
        { plates: %w[uuid purpose labware_barcode state_changes updated_at parents children] },
        { tubes: %w[uuid purpose labware_barcode state_changes updated_at parents children] }
      )
      .includes(:state_changes, :purpose, :parents, :children)
  end

  def decide_state(labware)
    changes = labware.state_changes
    return 'unknown' unless changes.respond_to?(:max_by)

    changes.max_by(&:id)&.target_state || 'pending'
  rescue StandardError
    'unknown'
  end

  # Build a Cytoscape graph by walking the real parent/child relationships
  # up (ancestors) and down (descendants) from the searched labware.
  def labware_to_cytoscape_graph(labware)
    nodes = {}
    edges = {}

    nodes[labware.uuid] = build_node(labware, searched: true)

    walk_up(labware, nodes, edges)
    walk_down(labware, nodes, edges)

    { elements: nodes.values + edges.values }
  end

  # Recursively walk parents, adding a node for each and an edge parent -> current
  def walk_up(labware, nodes, edges)
    safe_relatives(labware, :parents).each do |parent|
      nodes[parent.uuid] ||= build_node(parent)
      add_edge(edges, parent, labware)
      full_parent = retrieve_labware_by_uuid(parent.uuid)
      walk_up(full_parent, nodes, edges) if full_parent
    end
  end

  # Recursively walk children, adding a node for each and an edge current -> child
  def walk_down(labware, nodes, edges)
    safe_relatives(labware, :children).each do |child|
      nodes[child.uuid] ||= build_node(child)
      add_edge(edges, labware, child)
      full_child = retrieve_labware_by_uuid(child.uuid)
      walk_down(full_child, nodes, edges) if full_child
    end
  end

  # Safely fetch a relationship (parents/children), returning [] if it can't be loaded
  def safe_relatives(labware, relationship)
    result = labware.public_send(relationship)
    result.respond_to?(:to_a) ? result.to_a : []
  rescue StandardError
    []
  end

  # Add a real parent -> child edge, keyed to avoid duplicates
  def add_edge(edges, source, target)
    key = "#{source.uuid}->#{target.uuid}"
    edges[key] ||= {
      data: {
        source: source.uuid,
        target: target.uuid,
        pipeline: source.purpose&.name || 'unknown'
      }
    }
  end

  def build_node(item, searched: false)
    {
      data: {
        id: item.uuid,
        label: "#{item.labware_barcode&.human} (#{item.purpose&.name})",
        type: item.respond_to?(:type) ? item.type&.singularize : 'plate',
        size: 96,
        barcode: item.labware_barcode&.human,
        purpose: item.purpose&.name,
        state: decide_state(item),
        searched: searched
      }
    }
  end
end

# frozen_string_literal: true

# Controller for visualizing a single labware's pipeline workflow
class PipelineVisualiserController < ApplicationController
  def show
    barcode = params[:id]
    labware = retrieve_labware_by_barcode(barcode)

    return render_not_found unless labware

    @labware_data = {
      record: labware,
      state: decide_state(labware),
      ancestors: labware.ancestors
    }

    respond_to do |format|
      format.html
      format.json { render json: { graph_data: labware_to_cytoscape_graph(labware) } }
    end
  end

  private

  def render_not_found
    respond_to do |format|
      format.html { render status: :not_found }
      format.json { render json: { error: 'Labware not found' }, status: :not_found }
    end
  end

  def retrieve_labware_by_barcode(barcode)
    Sequencescape::Api::V2::Labware
      .select(
        { plates: %w[uuid purpose labware_barcode state_changes updated_at ancestors descendants] },
        { tubes: %w[uuid purpose labware_barcode state_changes updated_at ancestors descendants] }
      )
      .includes(:state_changes, :purpose, 'ancestors.purpose', 'descendants.purpose')
      .where(barcode:)
      .first
  end

  def decide_state(labware)
    labware.state_changes&.max_by(&:id)&.target_state || 'pending'
  end

  # Convert labware and ancestors into Cytoscape graph format
  def labware_to_cytoscape_graph(labware)
    all_labware = build_labware_chain(labware)
    nodes = all_labware.map { |item| build_node(item, searched: item.uuid == labware.uuid) }
    edges = build_edges(all_labware)

    { elements: nodes + edges }
  end

  # Oldest ancestor first, through to the searched labware, then its full descendant chain
  def build_labware_chain(labware)
    (labware.ancestors || []).reverse + [labware] + (labware.descendants || [])
  end

  def build_node(item, searched: false)
    {
      data: {
        id: item.uuid,
        label: "#{item.labware_barcode&.human} (#{item.purpose&.name})",
        type: item.class.name.demodulize.downcase,
        size: 96,
        barcode: item.labware_barcode&.human,
        purpose: item.purpose&.name,
        state: decide_state(item),
        searched: searched
      }
    }
  end

  def build_edges(all_labware)
    return [] if all_labware.length < 2

    Array.new(all_labware.length - 1) do |i|
      source = all_labware[i]
      target = all_labware[i + 1]

      {
        data: {
          source: source.uuid,
          target: target.uuid,
          pipeline: source.purpose&.name || 'unknown'
        }
      }
    end
  end
end

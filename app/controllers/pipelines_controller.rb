# frozen_string_literal: true

# Provides an overview of the pipelines auto-generated from the configuration
# Tailored to the needs of the pipeline graph
class PipelinesController < ApplicationController
  before_action :configure_api, except: :index
  def index
    respond_to do |format|
      # If we're html, just render the template, we'll populate it by ajax
      format.html { render :index }
      format.json do
        render json: { elements: { nodes: calculate_nodes, edges: calculate_edges }, pipelines: calculate_pipelines }
      end
    end
  end

  private

  def calculate_pipelines
    Settings.pipelines.map { |pl| { name: pl.name, filters: pl.filters } }
  end

  def calculate_edges_with_pipeline_data
    Settings.pipelines.flat_map { |pl| pl.relationships.map { |s, t| { source: s, target: t, pipeline: pl } } }
  end

  def calculate_pipeline_edges
    calculate_edges_with_pipeline_data.map do |edge|
      {
        group: 'edges',
        data: {
          id: SecureRandom.uuid,
          source: edge[:source],
          target: edge[:target],
          pipeline: edge[:pipeline].name
        }
      }
    end
  end

  def calculate_group_edges
    calculate_edges_with_pipeline_data
      .map do |edge|
        {
          group: 'edges',
          data: {
            id: SecureRandom.uuid,
            source: edge[:source],
            target: edge[:target],
            group: edge[:pipeline].pipeline_group
          }
        }
      end
      .uniq { |edge| edge[:data][:source] + edge[:data][:target] + edge[:data][:group] }
  end

  def calculate_edges
    calculate_pipeline_edges + calculate_group_edges
  end

  def calculate_nodes
    Settings.purposes.map do |_uuid, purpose|
      {
        group: 'nodes',
        data: {
          id: purpose[:name],
          type: purpose[:asset_type],
          input: purpose[:input_plate],
          stock: purpose[:stock_plate],
          cherrypickable_target: purpose[:cherrypickable_target],
          size: purpose[:size]
        }
      }
    end
  end
end

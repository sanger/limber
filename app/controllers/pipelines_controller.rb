# frozen_string_literal: true

# Provides an overview of the pipelines auto-generated from the configuration
# Currently still very quick and dirty
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

  def calculate_pipeline_edges
    Settings.pipelines.flat_map do |pl|
      pl.relationships.map do |s, t|
        { group: 'edges', data: { id: SecureRandom.uuid, source: s, target: t, pipeline: pl.name } }
      end
    end
  end

  def calculate_group_edges
    edges =
      Settings.pipelines.flat_map do |pl|
        pl.relationships.map do |s, t|
          { group: 'edges', data: { id: SecureRandom.uuid, source: s, target: t, group: pl.pipeline_group } }
        end
      end
    edges.uniq { |e| e[:data][:source] + e[:data][:target] + e[:data][:group] }
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

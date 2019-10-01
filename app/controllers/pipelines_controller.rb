# frozen_string_literal: true

# Provides an overview of the pipelines auto-generated from the configuration
# Currently still very quick and dirty
class PipelinesController < ApplicationController
  before_action :configure_api, except: :index
  def index
    @nodes = Settings.purposes.map do |_uuid, purpose|
      {
        group: 'nodes',
        data: { id: purpose[:name], type: purpose[:asset_type] }
      }
    end
    @edges = Settings.pipelines.flat_map do |pl|
      pl.relationships.map do |s, t|
        {
          group: 'edges',
          data: { id: SecureRandom.uuid, source: s, target: t, pipeline: pl.name }
        }
      end
    end
    @pipelines = Settings.pipelines.map do |pl|
      { name: pl.name, filters: pl.filters }
    end

    respond_to do |format|
      format.html { render :index }
      format.json do
        render json: {
          elements: { nodes: @nodes, edges: @edges },
          pipelines: @pipelines
        }
      end
    end
  end
end

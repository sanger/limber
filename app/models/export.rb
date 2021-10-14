# frozen_string_literal: true

require './lib/config_loader/exports_loader'

# An export is a means of generating a file for export, usually CSV containing
# data about the plate.
class Export
  include ActiveModel::AttributeAssignment
  # Raise if there is an attempt to find a non-existent model
  NotFound = Class.new(StandardError)

  class << self
    def loader
      @loader ||= ConfigLoader::ExportsLoader.new
    end

    def find(id)
      attributes = loader.config.fetch(id) { raise NotFound, "Could not find export #{id}" }
      Export.new(attributes)
    end
  end

  attr_accessor :csv, :plate_includes, :workflow, :ancestor_purpose, :filename

  def initialize(args = {})
    assign_attributes(args)
  end
end

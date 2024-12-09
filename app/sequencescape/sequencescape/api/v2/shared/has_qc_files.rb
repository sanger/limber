# frozen_string_literal: true

module Sequencescape::Api::V2::Shared
  # Include in an API V2 class that has a purpose to set up some standard behaviour
  module HasQcFiles
    extend ActiveSupport::Concern

    included { has_many :qc_files }
  end
end

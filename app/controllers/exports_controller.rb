# frozen_string_literal: true

require 'csv'

class ExportsController < ApplicationController
  before_action :locate_labware, only: :show

  def show
    render "plates/#{params[:id]}.csv"
  end

  private

  def configure_api
    # We don't use the V1 Sequencescape API here, so lets disable its initialization.
    # Probably should consider two controller classes as this expands.
  end

  def locate_labware
    @labware = @plate = Sequencescape::Api::V2::Plate.where(barcode: params[:limber_plate_id]).first
  end
end

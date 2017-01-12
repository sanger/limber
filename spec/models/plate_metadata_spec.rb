# frozen_string_literal: true
require 'rails_helper'
require 'pry'

describe PlateMetadata do

  include FeatureHelpers
  
  describe 'without api' do

    it 'is not valid without api' do
      expect(PlateMetadata.new).to_not be_valid
    end

  end

  describe 'with api' do

    let(:user_uuid)                 { SecureRandom.uuid }
    let(:user)                      { json :user, uuid: user_uuid }
    let(:plate_uuid)                { SecureRandom.uuid }
    let(:plate)                     { json :stock_plate, uuid: plate_uuid }
    let(:plate_with_metadata_uuid)  { SecureRandom.uuid }
    let(:plate_with_metadata)       { json :stock_plate_with_metadata, uuid: plate_with_metadata_uuid }

    has_a_working_api(times: 1)

    let(:api) { Sequencescape::Api.new(Limber::Application.config.api_connection_options) }

    it 'is not valid without a user' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate)
      expect(PlateMetadata.new(api: api, plate: 123, user: user_uuid)).to be_valid
      expect(PlateMetadata.new(api: api, plate: 123)).to_not be_valid
    end

    it 'is not valid without plate' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate)
      expect(PlateMetadata.new(api: api, plate: 123, user: user_uuid)).to be_valid
      expect(PlateMetadata.new(api: api, user: user_uuid)).to_not be_valid
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 456 } }, nil)
      expect(PlateMetadata.new(api: api, plate: 456, user: user_uuid)).to_not be_valid
    end

    it 'updates metadata' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => 123 } }, plate_with_metadata)
      plate_metadata = PlateMetadata.new(api: api, plate: 123, user: user_uuid, robot_barcode: 'robot')
      # allow(:plate).to receive(custom_metadatum_collection.create!).with(user: user_uuid, asset: plate_uuid, metadata: {robot_barcode: "robot_barcode"})
    end

  end

end
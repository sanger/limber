# frozen_string_literal: true
require 'rails_helper'

describe Robots::Robot do

  include FeatureHelpers

  has_a_working_api

  let(:api)             { Sequencescape::Api.new(Limber::Application.config.api_connection_options) }
  let(:settings)        { YAML::load_file(File.join(Rails.root, "spec", "data", "settings.yml")).with_indifferent_access }
  let(:user_uuid)       { SecureRandom.uuid }
  let(:plate_uuid)      { SecureRandom.uuid }
  let(:plate)           { json :stock_plate, uuid: plate_uuid }

  describe '#verify' do

    before(:each) do
      Settings.robots["robot_id"] = settings[:robots][:robot_id]
    end

    let(:robot) { Robots::Robot.find(id: "robot_id", api: api, user_uuid: user_uuid)}

    it 'returns an error if there is an invalid bed' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "dodgy_barcode" } }, nil)
      expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ["dodgy_barcode"])[:valid]).to be_falsey
    end

    it 'returns an error if the plate is not on the right bed' do
      stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => "plate_barcode" } }, plate)
      expect(robot.verify(settings[:robots][:robot_id][:beds].keys.first => ["plate_barcode"])[:valid]).to be_falsey
    end

    it 'returns an error if the robot barcode does not match the plate metadata robot barcode'

  end
end
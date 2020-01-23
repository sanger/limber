# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots, robots: true do
  include FeatureHelpers

  has_a_working_api

  let(:settings) { YAML.load_file(Rails.root.join('spec/data/settings.yml')).with_indifferent_access }

  before { Settings.robots = settings[:robots] }

  describe '::find' do
    let(:user_uuid) { SecureRandom.uuid }

    subject { Robots.find(id: robot_id, api: api, user_uuid: user_uuid) }

    context 'with a standard robot' do
      let(:robot_id) { 'robot_id' }

      it 'returns the expected robot' do
        expect(subject).to be_a(Robots::Robot)
        expect(subject.id).to eq(robot_id)
      end
    end

    context 'with a pooling robot' do
      let(:robot_id) { 'pooling_robot_id' }

      it 'returns the expected robot' do
        expect(subject).to be_a(Robots::PoolingRobot)
        expect(subject.id).to eq(robot_id)
      end
    end
  end

  describe '::each_robot' do
    it 'yields each robot name and id' do
      expect { |b| Robots.each_robot(&b) }.to yield_successive_args(
        %w[robot_id robot_name],
        %w[robot_id_2 robot_name],
        %w[grandparent_robot robot_name],
        ['bravo-lb-post-shear-to-lb-end-prep', 'bravo LB Post Shear => LB End Prep'],
        ['bravo-lb-end-prep', 'bravo LB End Prep'],
        ['pooling_robot_id', 'Pooling Robot']
      )
    end
  end
end

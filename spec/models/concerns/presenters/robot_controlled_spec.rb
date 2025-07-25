# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::RobotControlled do
  subject { dummy_class.new }

  let(:settings) do
    Hashie::Mash.new(
      YAML.safe_load_file(Rails.root.join('spec/data/settings.yml'), permitted_classes: [Symbol], aliases: true)
    )
  end

  let(:dummy_class) do
    Class.new do
      include Presenters::RobotControlled

      public :find_robots_with_parent_property
    end
  end

  describe '#find_robots_with_parent_property' do
    it 'returns empty array for non-hash input' do
      expect(subject.find_robots_with_parent_property('not a hash')).to eq([])
    end

    it 'returns empty array when no parent keys are found' do
      input = settings[:robots][:robot_id_2].beds
      expect(subject.find_robots_with_parent_property(input)).to eq([])
    end

    it 'returns all robots with a parent key' do
      input = settings[:robots][:grandparent_robot].beds
      result = subject.find_robots_with_parent_property(input)
      expect(result.size).to eq(2)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper do
  describe '#favicon' do
    subject(:favicon) { helper.favicon }

    it 'returns the favicon path for the production environment' do
      allow(Rails).to receive(:env).and_return('production')
      expect(favicon).to eq('favicon.ico')
    end

    it 'returns the favicon path for the training environment' do
      allow(Rails).to receive(:env).and_return('training')
      expect(favicon).to eq('favicon-training.ico')
    end

    it 'returns the favicon path for the staging environment' do
      allow(Rails).to receive(:env).and_return('staging')
      expect(favicon).to eq('favicon-staging.ico')
    end

    it 'returns the favicon path for the development environment' do
      allow(Rails).to receive(:env).and_return('development')
      expect(favicon).to eq('favicon-development.ico')
    end

    it 'returns the favicon path for an unknown environment' do
      allow(Rails).to receive(:env).and_return('unknown')
      expect(favicon).to eq('favicon-development.ico')
    end
  end

  describe '#apple_touch_icon' do
    subject(:apple_touch_icon) { helper.apple_touch_icon }

    it 'returns the apple-touch-icon path for the production environment' do
      allow(Rails).to receive(:env).and_return('production')
      expect(apple_touch_icon).to eq('apple-touch-icon.png')
    end

    it 'returns the apple-touch-icon path for the training environment' do
      allow(Rails).to receive(:env).and_return('training')
      expect(apple_touch_icon).to eq('apple-touch-icon-training.png')
    end

    it 'returns the apple-touch-icon path for the staging environment' do
      allow(Rails).to receive(:env).and_return('staging')
      expect(apple_touch_icon).to eq('apple-touch-icon-staging.png')
    end

    it 'returns the apple-touch-icon path for the development environment' do
      allow(Rails).to receive(:env).and_return('development')
      expect(apple_touch_icon).to eq('apple-touch-icon-development.png')
    end

    it 'returns the apple-touch-icon path for an unknown environment' do
      allow(Rails).to receive(:env).and_return('unknown')
      expect(apple_touch_icon).to eq('apple-touch-icon-development.png')
    end
  end
end

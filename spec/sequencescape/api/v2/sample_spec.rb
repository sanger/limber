# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sequencescape::Api::V2::Sample do
  describe '#component_samples_count' do
    let(:sample) { create :v2_sample, component_samples_count: component_samples_count }
    subject { sample.component_samples_count }

    context 'when a standard non composite sample' do
      let(:component_samples_count) { 0 }
      it { is_expected.to eq 1 }
    end

    context 'when a standard composite sample' do
      let(:component_samples_count) { 3 }
      it { is_expected.to eq component_samples_count }
    end
  end
end

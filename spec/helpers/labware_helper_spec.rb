# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareHelper do
  include LabwareHelper

  describe '::failable?' do
    subject { failable?(well) }

    context 'when passed a failed well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: false, control_info: nil) }
      it { is_expected.to be false }
    end

    context 'when passed a passed well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: nil) }
      it { is_expected.to be true }
    end

    context 'when passed a positive control well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: 'positive') }
      it { is_expected.to be true }
    end

    context 'when passed a negative control well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: 'negative') }
      it { is_expected.to be false }
    end
  end

  describe '::prevent_well_fail?' do
    subject { prevent_well_fail?(well) }

    context 'when passed a failed well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: false, control_info: nil) }
      it { is_expected.to be true }
    end

    context 'when passed a passed well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: nil) }
      it { is_expected.to be false }
    end

    context 'when passed a positive control well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: 'positive') }
      it { is_expected.to be false }
    end

    context 'when passed a negative control well' do
      let(:well) { instance_double(Sequencescape::Api::V2::Well, passed?: true, control_info: 'negative') }
      it { is_expected.to be false }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LabwareHelper do
  include LabwareHelper

  # def failable?(container)
  #   container.passed? && container.control_info != 'negative'
  # end
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
end

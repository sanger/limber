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

  describe '.labware_by_state' do
    subject { labware_by_state(labwares) }

    let(:labware1) { instance_double('Labware', state: 'completed') }
    let(:labware2) { instance_double('Labware', state: 'canceled') }
    let(:labware3) { instance_double('Labware', state: 'completed') }
    let(:labwares) { [labware1, labware2, labware3] }

    it 'groups labware by state' do
      is_expected.to eq({ 'completed' => [labware1, labware3], 'canceled' => [labware2] })
    end
  end

  describe '.labware_for_purpose' do
    subject { labware_for_purpose(labwares, 'purpose1') }

    let(:purpose1) { instance_double('Purpose', name: 'purpose1') }
    let(:purpose2) { instance_double('Purpose', name: 'purpose2') }
    let(:labware1) { instance_double('Labware', purpose: purpose1) }
    let(:labware2) { instance_double('Labware', purpose: purpose2) }
    let(:labware3) { instance_double('Labware', purpose: purpose1) }
    let(:labwares) { [labware1, labware2, labware3] }

    it 'selects labware for a specific purpose' do
      is_expected.to eq([labware1, labware3])
    end
  end
end

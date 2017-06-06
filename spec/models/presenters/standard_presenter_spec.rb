# frozen_string_literal: true

describe Presenters::StandardPresenter do
  has_a_working_api

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { build :plate, state: state, purpose_name: purpose_name }

  subject do
    Presenters::StandardPresenter.new(
      api:     api,
      labware: labware
    )
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'prevents child creation' do
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end

    it 'allows state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end
  end

  context 'when passed' do
    before do
      Settings.purposes = {
        'child-purpose' => { 'parents' => [purpose_name], 'name' => 'Child purpose', 'asset_type' => 'plate', 'form_class' => 'LabwareCreators::Base' },
        'other-purpose' => { 'parents' => [], 'name' => 'Other purpose', 'asset_type' => 'plate', 'form_class' => 'LabwareCreators::Base' },
        'tube-purpose' => { 'parents' => [], 'name' => 'Tube purpose', 'asset_type' => 'tube', 'form_class' => 'LabwareCreators::FinalTubeFromPlate' },
        'incompatible-tube-purpose' => { 'parents' => [], 'name' => 'Incompatible purpose', 'asset_type' => 'tube', 'form_class' => 'LabwareCreators::FinalTube' }
      }
    end

    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_with_args('child-purpose', 'Child purpose', 'plate')
    end

    it 'yields the configured plates' do
      expect { |b| subject.compatible_plate_purposes(&b) }.to yield_successive_args(
        ['child-purpose', 'Child purpose'],
        ['other-purpose', 'Other purpose']
      )
    end

    it 'yields the configured tube' do
      expect(labware).to receive(:tagged?).and_return(:true)
      expect { |b| subject.compatible_tube_purposes(&b) }.to yield_successive_args(
        ['tube-purpose', 'Tube purpose']
      )
    end
  end
end

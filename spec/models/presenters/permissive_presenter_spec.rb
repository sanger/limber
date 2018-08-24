# frozen_string_literal: true

RSpec.describe Presenters::PermissivePresenter do
  has_a_working_api

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { create :v2_plate, state: state, purpose_name: purpose_name }

  subject do
    Presenters::PermissivePresenter.new(
      api:     api,
      labware: labware
    )
  end

  before(:each) do
    Settings.purposes = {
      'child-purpose' => build(:purpose_config, parents: [purpose_name], name: 'Child purpose'),
      'other-purpose' => build(:purpose_config, parents: [], name: 'Other purpose')
    }
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'allows state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_with_args('child-purpose', 'Child purpose', 'plate')
    end
  end

  context 'when passed' do
    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_with_args('child-purpose', 'Child purpose', 'plate')
    end
  end
end

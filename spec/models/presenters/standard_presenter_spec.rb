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
    before(:each) do
      Settings.purposes = {
        'child-purpose' => { 'parents' => [purpose_name], 'name' => 'Child purpose' },
        'other-purpose' => { 'parents' => [], 'name' => 'Other purpose' }
      }
    end

    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_with_args('child-purpose', 'Child purpose')
    end
  end
end

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
        'child-purpose' => { 'parents' => [purpose_name], 'name' => 'Child purpose', 'asset_type' => 'plate' },
        'other-purpose' => { 'parents' => [], 'name' => 'Other purpose' }
      }
    end

    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_with_args('child-purpose', 'Child purpose', 'plate')
    end
  end

  context 'with tubes' do
    let(:labware) { build :plate, uuid: 'plate-uuid', transfers_to_tubes_count: 1 }

    before do
      stub_api_get('plate-uuid', 'transfers_to_tubes', body: json(:transfer_collection, size: 2))
    end

    it 'returns the correct number of labels' do
      expect(subject.tube_labels.length).to eq 2
    end
  end
end

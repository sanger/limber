# frozen_string_literal: true

RSpec.describe Presenters::RviCdnaXpPresenter do
  subject { described_class.new(labware:) }

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { create :plate, state: state, purpose_name: purpose_name, pool_sizes: [1] }

  before(:each) do
    create :purpose_config, uuid: 'child-purpose', name: 'Child purpose'
    create :purpose_config, uuid: 'other-purpose', name: 'Other purpose'
    create :pipeline, relationships: { purpose_name => 'Child purpose' }
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'does not allow child creation' do
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end

    it 'allows a default state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
    end
  end

  context 'when started' do
    let(:state) { 'started' }

    it 'does not allow child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'allows a default state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
    end
  end

  context 'when passed' do
    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
    end
  end
end

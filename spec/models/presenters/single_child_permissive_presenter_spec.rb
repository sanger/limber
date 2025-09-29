# frozen_string_literal: true

RSpec.describe Presenters::SingleChildPermissivePresenter do
  subject { described_class.new(labware:) }

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { create :plate, state: state, purpose_name: purpose_name, pool_sizes: [1] }
  let(:child_purpose) { 'Child purpose' }
  let(:child_plate) { create :plate, purpose_name: child_purpose }

  before(:each) do
    create :purpose_config, uuid: 'child-purpose', name: child_purpose
    create :purpose_config, uuid: 'other-purpose', name: 'Other purpose'
    create :pipeline, relationships: { purpose_name => child_purpose }
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'allows state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
    end

    context 'without child plates' do
      before(:each) { labware.child_plates = nil }

      it 'allows child creation' do
        expect { |b| subject.control_additional_creation(&b) }.to yield_control
      end
    end

    context 'with child plates' do
      before(:each) { labware.child_plates = [child_plate] }

      it 'does not allow child creation' do
        expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
      end
    end
  end

  context 'when passed' do
    let(:state) { 'passed' }

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
    end

    context 'without child plates' do
      before(:each) { labware.child_plates = nil }

      it 'allows child creation' do
        expect { |b| subject.control_additional_creation(&b) }.to yield_control
      end
    end

    context 'with child plates' do
      before(:each) { labware.child_plates = [child_plate] }

      it 'does not allow child creation' do
        expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
      end
    end
  end
end

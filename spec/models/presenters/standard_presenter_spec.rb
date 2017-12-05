# frozen_string_literal: true

describe Presenters::StandardPresenter do
  has_a_working_api

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { build :passed_plate, state: state, purpose_name: purpose_name, purpose_uuid: 'test-purpose', uuid: 'plate-uuid' }
  let(:suggest_passes) { nil }

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
        'child-purpose' => build(:purpose_config, name: 'Child purpose', parents: [purpose_name]),
        'child-purpose-2' => build(:purpose_config, name: 'Child purpose 2', parents: [purpose_name], expected_request_types: ['limber_multiplexing']),
        'other-purpose' => build(:purpose_config, name: 'Other purpose'),
        'other-purpose-2' => build(:purpose_config, name: 'Other purpose 2', parents: [purpose_name], expected_request_types: ['other_type']),
        'tube-purpose' => build(:tube_config, name: 'Tube purpose', creator_class: 'LabwareCreators::FinalTubeFromPlate'),
        'incompatible-tube-purpose' => build(:tube_config, name: 'Incompatible purpose', creator_class: 'LabwareCreators::FinalTube')
      }
    end

    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect { |b| subject.suggested_purposes(&b) }.to yield_successive_args(
        ['child-purpose', 'Child purpose', 'plate'],
        ['child-purpose-2', 'Child purpose 2', 'plate']
      )
    end

    it 'yields the configured plates' do
      expect { |b| subject.compatible_plate_purposes(&b) }.to yield_successive_args(
        ['child-purpose', 'Child purpose'],
        ['child-purpose-2', 'Child purpose 2'],
        ['other-purpose', 'Other purpose'],
        ['other-purpose-2', 'Other purpose 2']
      )
    end

    it 'yields the configured tube' do
      expect(labware).to receive(:tagged?).and_return(:true)
      expect { |b| subject.compatible_tube_purposes(&b) }.to yield_successive_args(
        ['tube-purpose', 'Tube purpose']
      )
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

  describe '#control_library_passing' do
    before do
      stub_api_get('plate-uuid', 'wells', body: json(:well_collection, size: 2, aliquot_factory: aliquot_type))
      Settings.purposes = { 'test-purpose' => build(:purpose_config, suggest_library_pass_for: suggest_passes) }
    end

    context 'tagged' do
      let(:aliquot_type) { :tagged_aliquot }

      context 'and passed' do
        let(:state) { 'passed' }

        context 'when not suggested' do
          it 'supports passing' do
            expect { |b| subject.control_library_passing(&b) }.to yield_control
          end
        end
        context 'when suggested' do
          let(:suggest_passes) { ['limber_multiplexing'] }
          it 'supports passing' do
            expect { |b| subject.control_library_passing(&b) }.not_to yield_control
          end
        end
      end

      context 'and pending' do
        let(:state) { 'pending' }
        it 'supports passing' do
          expect { |b| subject.control_library_passing(&b) }.not_to yield_control
        end
      end
    end

    context 'untagged' do
      let(:aliquot_type) { :aliquot }
      context 'and passed' do
        let(:state) { 'passed' }
        it 'supports passing' do
          expect { |b| subject.control_library_passing(&b) }.not_to yield_control
        end
      end
    end
  end

  describe '#control_suggested_library_passing' do
    before do
      stub_api_get('plate-uuid', 'wells', body: json(:well_collection, size: 2, aliquot_factory: :tagged_aliquot))
      Settings.purposes = { 'test-purpose' => build(:purpose_config, suggest_library_pass_for: suggest_passes) }
    end
    let(:suggest_passes) { ['limber_multiplexing'] }
    context 'and passed' do
      let(:state) { 'passed' }

      it 'suggests passing' do
        expect { |b| subject.control_suggested_library_passing(&b) }.to yield_control
      end
    end
    context 'and pending' do
      let(:state) { 'pending' }

      it 'suggests passing' do
        expect { |b| subject.control_suggested_library_passing(&b) }.not_to yield_control
      end
    end
  end
end

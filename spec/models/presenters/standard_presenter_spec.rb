# frozen_string_literal: true

RSpec.describe Presenters::StandardPresenter do
  has_a_working_api

  let(:purpose_name) { 'Example purpose' }
  let(:aliquot_type) { :v2_aliquot }
  let(:state) { 'pending' }
  let(:labware) do
    create :v2_plate,
           barcode_number: 1,
           state: state,
           purpose_name: purpose_name,
           purpose_uuid: 'test-purpose',
           uuid: 'plate-uuid',
           wells: wells
  end
  let(:wells) do
    [
      create(:v2_well, requests_as_source: create_list(:mx_request, 1, priority: 1), aliquots: create_list(aliquot_type, 1)),
      create(:v2_well, requests_as_source: create_list(:mx_request, 1, priority: 1), aliquots: create_list(aliquot_type, 1)),
      create(:v2_well, requests_as_source: create_list(:mx_request, 1, priority: 2), aliquots: create_list(aliquot_type, 1)),
      create(:v2_well, requests_as_source: create_list(:mx_request, 1, priority: 1), aliquots: create_list(aliquot_type, 1))
    ]
  end
  let(:suggest_passes) { nil }

  subject do
    Presenters::StandardPresenter.new(
      api:     api,
      labware: labware
    )
  end

  it 'returns the priority' do
    expect(subject.priority).to eq(2)
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'prevents child creation' do
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end

    it 'allows state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end

    it 'returns the labware state' do
      expect(subject.state).to eq(state)
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
      expect(labware).to receive(:tagged?).and_return(true)
      expect { |b| subject.compatible_tube_purposes(&b) }.to yield_successive_args(
        ['tube-purpose', 'Tube purpose']
      )
    end

    it 'returns the labware state' do
      expect(subject.state).to eq(state)
    end
  end

  describe '#control_library_passing' do
    before do
      Settings.purposes = { 'test-purpose' => build(:purpose_config, suggest_library_pass_for: suggest_passes) }
    end

    context 'tagged' do
      let(:aliquot_type) { :v2_tagged_aliquot }

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
      let(:aliquot_type) { :v2_aliquot }
      context 'and passed' do
        let(:state) { 'passed' }
        it 'supports passing' do
          expect { |b| subject.control_library_passing(&b) }.not_to yield_control
        end
      end
    end
  end

  describe '#control_suggested_library_passing' do
    let(:aliquot_type) { :v2_tagged_aliquot }
    before do
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

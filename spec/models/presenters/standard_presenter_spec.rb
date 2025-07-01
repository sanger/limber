# frozen_string_literal: true

RSpec.describe Presenters::StandardPresenter do
  subject { described_class.new(labware:) }

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
      create(
        :v2_well,
        requests_as_source: create_list(:mx_request, 1, priority: 1),
        aliquots: create_list(aliquot_type, 1)
      ),
      create(
        :v2_well,
        requests_as_source: create_list(:mx_request, 1, priority: 1),
        aliquots: create_list(aliquot_type, 1)
      ),
      create(
        :v2_well,
        requests_as_source: create_list(:mx_request, 1, priority: 2),
        aliquots: create_list(aliquot_type, 1)
      ),
      create(
        :v2_well,
        requests_as_source: create_list(:mx_request, 1, priority: 1),
        aliquots: create_list(aliquot_type, 1)
      )
    ]
  end
  let(:suggest_passes) { nil }

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
      create :pipeline, relationships: { purpose_name => 'Child purpose' }
      create :pipeline,
             relationships: {
               purpose_name => 'Child purpose 2'
             },
             filters: {
               'request_type_key' => ['limber_multiplexing']
             }
      create :pipeline,
             relationships: {
               purpose_name => 'Other purpose 2'
             },
             filters: {
               'request_type_key' => ['other_type']
             }
      create :purpose_config, name: 'Child purpose', uuid: 'child-purpose'
      create :purpose_config, name: 'Child purpose 2', uuid: 'child-purpose-2'
      create :purpose_config, name: 'Other purpose', uuid: 'other-purpose'
      create :purpose_config, name: 'Other purpose 2', uuid: 'other-purpose-2'
      create :tube_config,
             name: 'Tube purpose',
             creator_class: 'LabwareCreators::FinalTubeFromPlate',
             uuid: 'tube-purpose'
      create :tube_config,
             name: 'Incompatible purpose',
             creator_class: 'LabwareCreators::FinalTube',
             uuid: 'incompatible-tube-purpose'
    end

    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes).to be_an Array
      expect(subject.suggested_purposes.length).to eq 2
      expect(subject.suggested_purposes.first).to be_a LabwareCreators::CreatorButton
      expect(subject.suggested_purposes.first.purpose_uuid).to eq('child-purpose')
      expect(subject.suggested_purposes.last.purpose_uuid).to eq('child-purpose-2')
    end

    it 'yields the configured plates' do
      cpp = subject.compatible_plate_purposes
      expect(cpp).to be_an Array
      expect(cpp.length).to eq 4
      expect(cpp.map(&:purpose_uuid)).to eq(%w[child-purpose child-purpose-2 other-purpose other-purpose-2])
    end

    it 'yields the configured tube' do
      expect(labware).to receive(:tagged?).and_return(true)
      ctp = subject.compatible_tube_purposes
      expect(ctp).to be_an Array
      expect(ctp.length).to eq 1
      expect(ctp.first.purpose_uuid).to eq 'tube-purpose'
    end

    it 'returns the labware state' do
      expect(subject.state).to eq(state)
    end
  end

  context 'before passing' do
    let(:wells) do
      [
        create(
          :v2_well,
          requests_as_source: [],
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'started'))
        ),
        create(
          :v2_well,
          requests_as_source: [],
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'started'))
        ),
        create(
          :v2_well,
          requests_as_source: [],
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'started'))
        ),
        create(
          :v2_well,
          requests_as_source: [],
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'started'))
        )
      ]
    end

    describe '#control_library_passing' do
      before do
        create :pipeline,
               relationships: {
                 'Example purpose' => 'Next example purpose'
               },
               filters: {
                 'request_type_key' => suggest_passes
               },
               library_pass: 'Example purpose'
        create(:purpose_config, name: 'Example purpose', uuid: 'test-purpose')
      end

      context 'tagged' do
        let(:aliquot_type) { :v2_tagged_aliquot }

        context 'and passed' do
          let(:state) { 'passed' }

          context 'when not suggested' do
            let(:suggest_passes) { ['other_pipeline'] }

            it 'supports passing' do
              expect { |b| subject.control_library_passing(&b) }.to yield_control
            end
          end

          context 'when suggested' do
            let(:suggest_passes) { ['limber_wgs'] }

            it 'does not have inactive passing' do
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
        create :pipeline,
               relationships: {
                 'Example purpose' => 'Next example purpose'
               },
               filters: {
                 request_type_key: suggest_passes
               },
               library_pass: 'Example purpose'
        create(:purpose_config, uuid: 'test-purpose', name: 'Example purpose')
      end

      let(:suggest_passes) { ['limber_wgs'] }

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

  context 'after passing' do
    let(:wells) do
      [
        create(
          :v2_well,
          requests_as_source: create_list(:mx_request, 1, priority: 1),
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'passed'))
        ),
        create(
          :v2_well,
          requests_as_source: create_list(:mx_request, 1, priority: 1),
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'passed'))
        ),
        create(
          :v2_well,
          requests_as_source: [],
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'failed'))
        ),
        create(
          :v2_well,
          requests_as_source: create_list(:mx_request, 1, priority: 1),
          aliquots: create_list(aliquot_type, 1, request: create(:library_request, state: 'passed'))
        )
      ]
    end

    describe '#control_library_passing' do
      before do
        create :pipeline, filters: { request_type_key: suggest_passes }, library_pass: 'Example purpose'
        create(:purpose_config, uuid: 'test-purpose', name: 'Example purpose')
      end

      context 'tagged' do
        let(:aliquot_type) { :v2_tagged_aliquot }

        context 'and passed' do
          let(:state) { 'passed' }

          context 'when not suggested' do
            it 'supports passing' do
              expect { |b| subject.control_library_passing(&b) }.not_to yield_control
            end
          end

          context 'when suggested' do
            let(:suggest_passes) { ['limber_wgs'] }

            it 'does not have inactive passing' do
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
        create :pipeline, filters: { request_type_key: suggest_passes }, library_pass: 'Example purpose'
        create(:purpose_config, uuid: 'test-purpose', name: 'Example purpose')
      end

      let(:suggest_passes) { ['limber_wgs'] }

      context 'and passed' do
        let(:state) { 'passed' }

        it 'suggests passing' do
          expect { |b| subject.control_suggested_library_passing(&b) }.not_to yield_control
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
end

# frozen_string_literal: true

RSpec.describe Presenters::SimpleTubePresenter do
  subject { described_class.new(labware:) }

  let(:labware) { build :tube, state: }

  before do
    create(:purpose_config, name: 'Example Plate Purpose', uuid: 'example-purpose-uuid-1')
    create(:purpose_config, name: 'Example Plate Purpose 2', uuid: 'example-purpose-uuid-2')
    create(
      :tube_config,
      name: 'Example Tube Purpose',
      creator_class: 'LabwareCreators::TubeFromTube',
      uuid: 'example-purpose-uuid-3'
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
    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'yields the configured plates' do
      # No plates, as you can't make plates from tools
      expect { |b| subject.compatible_plate_purposes(&b) }.not_to yield_control
    end

    it 'returns an array for compatible tube purposes' do
      ctp = subject.compatible_tube_purposes
      expect(ctp).to be_an Array
    end

    it 'returns one compatible tube purpose' do
      ctp = subject.compatible_tube_purposes
      expect(ctp.length).to eq 1
    end

    it 'returns the correct purpose_uuid for the compatible tube purpose' do
      ctp = subject.compatible_tube_purposes
      expect(ctp.first.purpose_uuid).to eq 'example-purpose-uuid-3'
    end
  end

  context 'when the child tube is a multiplexed tube' do
    let(:state) { 'passed' }

    let(:parent_tube_purpose_name) { 'Example Parent Tube Purpose' }
    let(:parent_tube_purpose_uuid) { 'example-parent-tube-purpose-uuid' }

    let(:parent_tube_uuid) { 'parent-tube-uuid' }
    let(:labware) do
      create :tube,
             uuid: parent_tube_uuid,
             state: 'passed',
             purpose_name: parent_tube_purpose_name,
             purpose_uuid: parent_tube_purpose_uuid
    end

    let(:child_tube_purpose_name) { 'Example Child Tube Purpose' }
    let(:child_tube_purpose_uuid) { 'example-child-tube-purpose-uuid' }

    before do
      create(
        :tube_config,
        name: parent_tube_purpose_name,
        creator_class: 'LabwareCreators::TubeFromTube',
        presenter_class: {
          name: 'Presenters::SimpleTubePresenter',
          args: {
            downstream_mx_tube: {
              child_tube_purposes_to_limit: [child_tube_purpose_name]
            }
          }
        },
        uuid: parent_tube_purpose_uuid
      )
      create(
        :tube_config,
        name: child_tube_purpose_name,
        creator_class: 'LabwareCreators::TubeFromTube',
        uuid: child_tube_purpose_uuid
      )
      create :pipeline, relationships: { parent_tube_purpose_name => child_tube_purpose_name }
    end

    context 'when there are no matching downstream tubes' do
      let(:state) { 'passed' }

      before do
        allow(labware).to receive(:descendants).and_return([])
      end

      it 'allows specific child creation' do
        expect(subject.allow_specific_child_creation?).to be true
      end

      it 'returns the correct uuid for the first suggested purpose option' do
        expect(subject.suggested_purpose_options.first[0]).to eq(child_tube_purpose_uuid)
      end

      it 'returns the correct name for the first suggested purpose option' do
        expect(subject.suggested_purpose_options.first[1].name).to eq(child_tube_purpose_name)
      end

      it 'has no tube warnings for suggested options' do
        expect(subject.suggested_options_warnings[:tube]).to be_empty
      end
    end

    context 'when a matching downstream tube exists' do
      let(:state) { 'passed' }
      let(:child_tube_uuid) { 'child-tube-uuid' }

      let(:child_tube) do
        create :tube,
               uuid: child_tube_uuid,
               state: 'passed',
               purpose_name: child_tube_purpose_name,
               purpose_uuid: child_tube_purpose_uuid
      end

      let(:mx_submission) { create(:submission, state: 'pending') }

      let(:mx_request) do
        create(:mx_request, state: 'pending', include_submissions: true, submission: mx_submission)
      end

      before do
        allow(labware).to receive(:descendants).and_return([child_tube])

        # set up a mx request on the child tube first aliquot
        child_tube.aliquots.first.request = mx_request

        stub_find_by(Sequencescape::Api::V2::Tube, child_tube,
                     custom_includes: described_class::DESCENDANT_TUBE_INCLUDES)
      end

      it 'does not allow specific child creation' do
        expect(subject.allow_specific_child_creation?).to be false
      end

      it 'filters out the restricted child tube purpose' do
        # NB. use force to evaluate the lazy enumerator
        result = subject.suggested_purpose_options.force
        expect(result).to eq([])
      end

      it 'adds a warning for the restricted child tube purpose' do
        # NB. use force to evaluate the lazy enumerator
        subject.suggested_purpose_options.force
        expect(subject.suggested_options_warnings[:tube].first).to include('has been hidden')
      end
    end

    context 'when chid tube does not match requirements' do
      let(:state) { 'passed' }
      let(:some_other_child_tube_uuid) { 'some-other-child-tube-uuid' }

      let(:some_other_child_tube_purpose_name) { 'Some Other Child Tube Purpose' }
      let(:some_other_child_tube_purpose_uuid) { 'some-other-child-tube-purpose-uuid' }

      let(:some_other_child_tube) do
        create :tube,
               uuid: some_other_child_tube_uuid,
               state: 'passed',
               purpose_name: some_other_child_tube_purpose_name,
               purpose_uuid: some_other_child_tube_purpose_uuid
      end

      before do
        create(
          :tube_config,
          name: some_other_child_tube_purpose_name,
          creator_class: 'LabwareCreators::TubeFromTube',
          uuid: some_other_child_tube_purpose_uuid
        )
        create :pipeline, relationships: { parent_tube_purpose_name => some_other_child_tube_purpose_name }

        allow(labware).to receive(:descendants).and_return([some_other_child_tube])

        stub_find_by(Sequencescape::Api::V2::Tube, some_other_child_tube,
                     custom_includes: described_class::DESCENDANT_TUBE_INCLUDES)
      end

      it 'does not filter out the other child purpose from creation' do
        expect(subject.suggested_purpose_options.force.pluck(0)).to include(some_other_child_tube_purpose_uuid)
      end

      it 'returns false from tube_matches_requirements?' do
        expect(subject.send(:tube_matches_requirements?, some_other_child_tube)).to be false
      end

      it 'has no tube warnings for suggested options' do
        subject.send(:tube_matches_requirements?, some_other_child_tube)
        expect(subject.suggested_options_warnings[:tube]).to be_empty
      end
    end
  end
end

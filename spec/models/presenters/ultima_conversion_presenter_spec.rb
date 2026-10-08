# frozen_string_literal: true

RSpec.describe Presenters::UltimaConversionPresenter do
  subject { described_class.new(labware:) }

  let(:purpose_name) { 'Example purpose' }
  let(:labware) { create :plate, state: state, purpose_name: purpose_name, pool_sizes: [1] }

  before do
    create :purpose_config, uuid: 'child-purpose', name: 'Child purpose'
    create :pipeline, relationships: { purpose_name => 'Child purpose' }
  end

  # The state the Manual Transfer button changes to
  def default_target_state
    target = nil
    subject.default_state_change { |transition| target = transition.to }
    target
  end

  # The states offered under 'Other changes'
  def other_target_states
    targets = []
    subject.control_state_change { |transitions| targets = transitions.map(&:to) }
    targets
  end

  shared_examples 'a step before the PCR is done' do
    it 'does not allow child creation' do
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end

    it 'does not allow library passing' do
      expect { |b| subject.control_library_passing(&b) }.not_to yield_control
    end

    it 'does not allow skipping to passed' do
      expect(other_target_states).not_to include('passed')
    end

    it 'allows failing and cancelling' do
      expect(other_target_states).to include('failed', 'cancelled')
    end
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it_behaves_like 'a step before the PCR is done'

    it 'changes to processed_1 with the default state change' do
      expect(default_target_state).to eq('processed_1')
    end

    it 'shows the wells without tags' do
      expect(subject.aliquot_partial).to eq('standard_aliquot')
    end

    it 'shows a reminder for the normalisation' do
      expect(subject.info_messages).to contain_exactly(described_class::STATE_MESSAGES['pending'])
    end
  end

  context 'when processed_1' do
    let(:state) { 'processed_1' }

    it_behaves_like 'a step before the PCR is done'

    it 'does not have a default state change, as the tags are added on the tagging page' do
      expect { |b| subject.default_state_change(&b) }.not_to yield_control
    end

    it 'allows tagging when there is a submission for the next step' do
      expect(subject).to be_tagging_allowed
    end

    it 'shows a reminder for the tagging' do
      expect(subject.info_messages).to contain_exactly(described_class::STATE_MESSAGES['processed_1'])
    end

    context 'without a submission for the next step' do
      before { Settings.pipelines = PipelineList.new }

      it 'does not allow tagging' do
        expect(subject).not_to be_tagging_allowed
      end
    end
  end

  context 'when processed_2' do
    let(:state) { 'processed_2' }

    it_behaves_like 'a step before the PCR is done'

    it 'does not allow tagging again' do
      expect(subject).not_to be_tagging_allowed
    end

    it 'shows the tags in the wells' do
      expect(subject.aliquot_partial).to eq('tagged_aliquot')
    end

    it 'changes to passed with the default state change' do
      expect(default_target_state).to eq('passed')
    end

    it 'shows a reminder for the PCR' do
      expect(subject.info_messages).to contain_exactly(described_class::STATE_MESSAGES['processed_2'])
    end
  end

  context 'when passed' do
    let(:state) { 'passed' }

    it 'allows child creation' do
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end

    it 'suggests child purposes' do
      expect(subject.suggested_purposes.map(&:purpose_uuid)).to eq(['child-purpose'])
    end

    it 'does not have a default state change' do
      expect { |b| subject.default_state_change(&b) }.not_to yield_control
    end

    it 'shows the tags in the wells' do
      expect(subject.aliquot_partial).to eq('tagged_aliquot')
    end

    it 'shows no reminders' do
      expect(subject.info_messages).to be_empty
    end
  end

  context 'when failed' do
    let(:state) { 'failed' }

    it 'does not allow child creation' do
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end
  end

  describe 'button labels' do
    let(:state) { 'processed_1' }
    let(:default_target_states) { %w[processed_1 passed] }

    %w[transitions transitioning].each do |label_type|
      it "has #{label_type} labels for each default state change" do
        labels = default_target_states.map do |target|
          I18n.t(target, scope: [:state_machine, :ultima_conversion, label_type], raise: true)
        end
        expect(labels).to all(be_present)
      end
    end

    it 'has a label for the tagging link' do
      expect(subject.tagging_label).to eq('Add Ultima Tags')
    end
  end
end

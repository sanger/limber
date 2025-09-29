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

    it 'yields the configured tube' do
      ctp = subject.compatible_tube_purposes
      expect(ctp).to be_an Array
      expect(ctp.length).to eq 1
      expect(ctp.first.purpose_uuid).to eq 'example-purpose-uuid-3'
    end
  end
end

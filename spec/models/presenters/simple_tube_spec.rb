# frozen_string_literal: true

describe Presenters::SimpleTubePresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) { build :tube, state: state }

  subject do
    Presenters::SimpleTubePresenter.new(
      api:     api,
      labware: labware
    )
  end

  before(:all) do
    Settings.purposes = {
      'example-purpose-uuid-1' => build(:purpose_config, name: 'Example Plate Purpose'),
      'example-purpose-uuid-2' => build(:purpose_config, name: 'Example Plate Purpose 2'),
      'example-purpose-uuid-3' => build(:tube_config, name: 'Example Tube Purpose', creator_class: 'LabwareCreators::TubeFromTube')
    }
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
      expect { |b| subject.compatible_tube_purposes(&b) }.to yield_successive_args(
        ['example-purpose-uuid-3', 'Example Tube Purpose']
      )
    end
  end
end

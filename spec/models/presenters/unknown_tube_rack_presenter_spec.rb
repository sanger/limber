# frozen_string_literal: true

RSpec.describe Presenters::UnknownTubeRackPresenter do
  let(:labware) { create :tube_rack, purpose_name: 'Other tube rack' }

  subject { described_class.new(labware:) }

  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end

  it 'prevents child creation' do
    expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
  end

  it 'prevents well failure' do
    expect(subject.well_failing_applicable?).to eq false
  end

  context 'with a well request' do
    before { stub_api_get(labware.uuid, 'wells', body: json(:well_collection)) }

    it { is_expected.not_to be_valid }

    it 'warns the user' do
      subject.valid?
      expect(subject.errors.full_messages).to include(
        "Tube rack type 'Other tube rack' is not a limber tube rack. " \
          'Perhaps you are using the wrong pipeline application?'
      )
    end
  end
end

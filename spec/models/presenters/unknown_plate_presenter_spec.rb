# frozen_string_literal: true

RSpec.describe Presenters::UnknownPlatePresenter do
  subject { described_class.new(labware:) }

  let(:labware) { create :plate, purpose_name: 'Other plate' }

  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end

  it 'prevents child creation' do
    expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
  end

  it 'prevents well failure' do
    expect(subject.well_failing_applicable?).to be false
  end

  context 'with a well request' do
    it { is_expected.not_to be_valid }

    it 'warns the user' do
      subject.valid?
      expect(subject.errors.full_messages).to include(
        "Plate type 'Other plate' is not a limber plate. Perhaps you are using the wrong pipeline application?"
      )
    end
  end
end

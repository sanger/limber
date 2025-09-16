# frozen_string_literal: true

RSpec.describe Presenters::UnknownTubeRackPresenter do
  subject { described_class.new(labware:) }

  let(:labware) { create :tube_rack, purpose_name: 'Other tube rack' }

  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end

  # TODO: unsure what additional tests are needed here
end

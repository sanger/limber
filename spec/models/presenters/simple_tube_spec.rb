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

  let(:expect_child_purpose_requests) do
    stub_api_get('example-purpose-uuid', body: json(:tube_purpose, uuid: 'example-purpose-uuid'))
    stub_api_get('example-purpose-uuid','children', body: json(:plate_purpose_collection, size: 1))
  end

  context 'when pending' do
    let(:state) { 'pending' }

    it 'prevents child creation' do
      expect_child_purpose_requests
      expect { |b| subject.control_additional_creation(&b) }.not_to yield_control
    end

    it 'allows state change' do
      expect { |b| subject.default_state_change(&b) }.to yield_control
    end
  end

  context 'when passed' do
    let(:state) { 'passed' }

    it 'allows child creation' do
      expect_child_purpose_requests
      expect { |b| subject.control_additional_creation(&b) }.to yield_control
    end
  end
end

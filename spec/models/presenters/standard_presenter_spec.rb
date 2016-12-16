# frozen_string_literal: true
describe Presenters::StandardPresenter do
  # Not sure why this is getting executed twice.
  # Want to get the basics working first though
  has_a_working_api(times: 2)

  let(:labware) { build :plate, state: state}

  subject do
    Presenters::StandardPresenter.new(
      api:     api,
      labware: labware
    )
  end

  let(:expect_child_purpose_requests) do
    stub_request(:get, 'http://example.com:3000/stock-plate-purpose-uuid')
      .to_return(status: 200, body: json(:stock_plate_purpose), headers: { 'content-type' => 'application/json' })
    stub_request(:get, 'http://example.com:3000/stock-plate-purpose-uuid/children')
      .to_return(status: 200, body: json(:plate_purpose_collection, size: 1), headers: { 'content-type' => 'application/json' })
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

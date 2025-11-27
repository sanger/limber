# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::RequestInfoPresenter do
  let(:labware) { create(:plate) }
  let(:presenter) { described_class.new(labware) }

  describe '#labware' do
    it 'returns the labware' do
      expect(presenter.labware).to eq(labware)
    end
  end

  describe '#uuid' do
    it 'delegates to labware' do
      allow(labware).to receive(:uuid).and_return('abc-123')
      expect(presenter.uuid).to eq('abc-123')
    end
  end

  describe '#active_requests' do
    let(:requests) { [create(:request), create(:request)] }

    before do
      allow(labware).to receive(:active_requests).and_return(requests)
    end

    it 'delegates to labware' do
      expect(presenter.active_requests).to eq(requests)
    end
  end

  describe '#grouped_active_requests' do
    let(:library_request_type) { create(:library_request_type) }
    let(:mx_request_type) { create(:mx_request_type) }

    let(:library_request_passed) { create(:request, request_type: library_request_type, state: 'passed') }
    let(:library_request_failed) { create(:request, request_type: library_request_type, state: 'failed') }
    let(:mx_request_passed) { create(:request, request_type: mx_request_type, state: 'passed') }

    let(:requests) { [library_request_failed, library_request_passed, mx_request_passed] }

    before do
      allow(labware).to receive(:active_requests).and_return(requests)
    end

    it 'groups active requests by name and state by default' do
      expect(presenter.grouped_active_requests).to eq(
        { ['Limber WGS', 'failed'] => 1, ['Limber WGS', 'passed'] => 1, ['Limber Multiplexing', 'passed'] => 1 }
      )
    end

    it 'groups active requests by custom attributes' do
      expect(presenter.grouped_active_requests(by: [:state])).to eq(
        { ['passed'] => 2, ['failed'] => 1 }
      )
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PageHelper do
  include described_class

  describe '::count_badge' do
    it 'returns a grey (secondary) badge for 0 counts' do
      expect(count_badge(0)).to eq('<span class="badge rounded-pill bg-secondary">0</span>')
    end

    it 'returns a blue (primary) badge for >0 counts' do
      expect(count_badge(10)).to eq('<span class="badge rounded-pill bg-primary">10</span>')
    end

    it 'returns a spinner for nil counts' do
      expect(count_badge(nil)).to eq('<span class="badge rounded-pill bg-secondary">...</span>')
    end

    it 'lets us customise the id' do
      expect(count_badge(0, 'test')).to eq('<span class="badge rounded-pill bg-secondary" id="test">0</span>')
    end
  end

  describe '::state_badge' do
    it 'returns a badge with the given state and default title' do
      expect(state_badge('pending')).to eq(
        '<span class="state-badge pending" title="Labware State" data-bs-toggle="tooltip">Pending</span>'
      )
    end

    it 'returns a badge with the given state and title' do
      expect(state_badge('passed', title: 'Submission State')).to eq(
        '<span class="state-badge passed" title="Submission State" data-bs-toggle="tooltip">Passed</span>'
      )
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Presenters::SubmissionBehaviour do
  let(:dummy_class) do
    Class.new do
      include Presenters::SubmissionBehaviour

      attr_accessor :labware
    end
  end

  let(:instance) { dummy_class.new }
  let(:wells) { [] }
  let(:labware) do
    create :plate, wells: wells, direct_submissions: submissions
  end

  let(:submissions) { [] }

  before { instance.labware = labware }

  describe '#active_submissions?' do
    context 'when there are no submissions' do
      let(:submissions) { [] }

      it 'returns false' do
        expect(instance.send(:active_submissions?)).to be false
      end
    end

    context 'when not all submissions are ready' do
      let(:submissions) { [build(:submission, ready?: false)] }

      it 'returns false' do
        expect(instance.send(:active_submissions?)).to be false
      end
    end

    context 'when all submissions are ready but no wells have incomplete requests' do
      let(:submissions) { [build(:submission, ready?: true)] }
      let(:wells) do
        [build(:well, location: 'A1', requests_as_source: [build(:request, state: 'passed')])]
      end

      it 'returns false' do
        expect(instance.send(:active_submissions?)).to be false
      end
    end

    context 'when all submissions are ready and at least one well has an incomplete request' do
      let(:submissions) { [build(:submission, ready?: true)] }
      let(:wells) do
        [build(:well, location: 'A1', requests_as_source: [build(:request, state: 'pending')])]
      end

      it 'returns true' do
        expect(instance.send(:active_submissions?)).to be true
      end
    end

    context 'when multiple wells, some with incomplete requests' do
      let(:submissions) { [build(:submission, ready?: true)] }
      let(:wells) do
        [
          build(:well, location: 'A1', requests_as_source: [build(:request, state: 'passed')]),
          build(:well, location: 'B1', requests_as_source: [build(:request, state: 'pending')])
        ]
      end

      it 'returns true' do
        expect(instance.send(:active_submissions?)).to be true
      end
    end

    context 'when multiple submissions, all ready, some wells with incomplete requests' do
      let(:submissions) { [build(:submission, ready?: true), build(:submission, ready?: true)] }
      let(:wells) do
        [build(:well, location: 'A1', requests_as_source: [build(:request, state: 'pending')])]
      end

      it 'returns true' do
        expect(instance.send(:active_submissions?)).to be true
      end
    end
  end

  describe '#submission_ready_with_incomplete_requests?' do
    let(:submission) { build(:submission, state: submission_state) }
    let(:wells) do
      [build(:well, location: 'A1', requests_as_source: [build(:request, state: request_state)])]
    end

    let(:submissions) { [submission] }

    before { instance.labware = labware }

    context 'when submission is not ready' do
      let(:submission_state) { 'pending' }
      let(:request_state) { 'pending' }

      it 'returns false' do
        expect(instance.send(:submission_ready_with_incomplete_requests?, submission)).to be false
      end
    end

    context 'when submission is ready and well has incomplete request' do
      let(:submission_state) { 'ready' }
      let(:request_state) { 'pending' }

      it 'returns true' do
        expect(instance.send(:submission_ready_with_incomplete_requests?, submission)).to be true
      end
    end

    context 'when submission is ready and well has only completed requests' do
      let(:submission_state) { 'ready' }
      let(:request_state) { 'passed' }

      it 'returns false' do
        expect(instance.send(:submission_ready_with_incomplete_requests?, submission)).to be false
      end
    end
  end

  describe '#incomplete_requests?' do
    context 'when labware is a tube' do
      subject { instance.incomplete_requests?(tube) }

      let(:tube) { build(:tube, requests_as_source: requests) }

      context 'when all requests are completed' do
        let(:requests) { [build(:request, state: 'passed'), build(:request, state: 'failed')] }

        it 'returns false' do
          expect(instance.send(:incomplete_requests?, tube)).to be false
        end
      end

      context 'when at least one request is incomplete' do
        let(:requests) { [build(:request, state: 'pending'), build(:request, state: 'passed')] }

        it 'returns true' do
          expect(instance.send(:incomplete_requests?, tube)).to be true
        end
      end
    end

    context 'when labware is a plate' do
      subject { instance.incomplete_requests?(well) }

      let(:well) { build(:well, location: 'A1', requests_as_source: requests) }

      context 'when all requests are completed' do
        let(:requests) { [build(:request, state: 'passed'), build(:request, state: 'failed')] }

        it 'returns false' do
          expect(instance.send(:incomplete_requests?, well)).to be false
        end
      end

      context 'when at least one request is incomplete' do
        let(:requests) { [build(:request, state: 'pending'), build(:request, state: 'passed')] }

        it 'returns true' do
          expect(instance.send(:incomplete_requests?, well)).to be true
        end
      end
    end
  end

  describe '#incomplete_request_state?' do
    it 'returns true for pending' do
      expect(instance.send(:incomplete_request_state?, 'pending')).to be true
    end

    it 'returns false for passed' do
      expect(instance.send(:incomplete_request_state?, 'passed')).to be false
    end

    it 'returns false for failed' do
      expect(instance.send(:incomplete_request_state?, 'failed')).to be false
    end

    it 'returns false for cancelled' do
      expect(instance.send(:incomplete_request_state?, 'cancelled')).to be false
    end
  end
end

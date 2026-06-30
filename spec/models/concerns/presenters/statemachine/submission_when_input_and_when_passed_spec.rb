# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Presenters::Statemachine::SubmissionWhenInputAndWhenPassed do
  subject(:instance) { klass.new }

  let(:klass) do
    Class.new do
      include Presenters::Statemachine::SubmissionWhenInputAndWhenPassed

      attr_accessor :state
    end
  end

  describe 'sidebar_partial' do
    context 'when state is pending' do
      before { instance.state = 'pending' }

      it 'returns submission' do
        expect(instance.sidebar_partial).to eq('submission')
      end
    end

    context 'when state is passed' do
      before { instance.state = 'passed' }

      it 'returns submission_default' do
        expect(instance.sidebar_partial).to eq('submission_default')
      end
    end
  end
end

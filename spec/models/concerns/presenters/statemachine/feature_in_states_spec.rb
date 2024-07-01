# frozen_string_literal: true

require 'rails_helper'

# Test presenter class that includes the FeatureInStates module.
class TestPresenter
  include Presenters::Statemachine::FeatureInStates

  attr_accessor :state

  def initialize(state)
    @state = state
  end
end

# Test presenter class that includes the FeatureInStates module
# but does not have a state attribute.
class TestPresenterWithNoState
  include Presenters::Statemachine::FeatureInStates
end

# This test case cover common cases for the can_be_enabled? method.
# The following are some example YAML configurations:
#
# feature1:
#  states: pending
# feature2:
#  states: :pending
# feature3:
#  :states: pending
# feature4:
#  states: [pending, passed]
# feature5:
#   states:
#     - pending
#     - passed
# feature6:
#   states:
#     includes: passed
# feature7:
#   states:
#     excludes: pending
# feature8:
#   states:
#     includes: [pending, passed]
#     excludes: completed
# feature9:
#   states:
#     excludes: [pending, completed]
# feature10:
#   states:
#     includes:
#       - pending
#       - passed
#     excludes:
#       - completed
RSpec.describe Presenters::Statemachine::FeatureInStates do
  let(:presenter) { TestPresenter.new(state) }

  describe '#can_be_enabled?' do
    context 'when the instance state is nil' do
      let(:state) { nil }

      it 'returns the default value' do
        expect(presenter.can_be_enabled?('pending')).to be true
      end
    end

    context 'when the instance does not respond to state' do
      let(:presenter) { TestPresenterWithNoState.new }

      it 'returns the default value' do
        expect(presenter.respond_to?(:state)).to be false
        expect(presenter.can_be_enabled?('pending')).to be true
      end
    end

    context 'when the states parameter is nil' do
      let(:state) { 'pending' }

      it 'returns the default value' do
        expect(presenter.can_be_enabled?(nil)).to be true
      end
    end

    context 'when the states parameter is a symbol' do
      let(:state) { 'pending' }

      it 'returns true if the current state matches the symbol' do
        expect(presenter.can_be_enabled?(:pending)).to be true
      end
    end

    context 'when the state is not in the includes list' do
      let(:state) { 'pending' }

      it 'returns false' do
        expect(presenter.can_be_enabled?('started')).to be false
      end
    end

    context 'when the state is in the includes list' do
      let(:state) { 'pending' }

      it 'returns true' do
        expect(presenter.can_be_enabled?('pending')).to be true
      end
    end

    context 'when the state is in the excludes list' do
      let(:state) { 'pending' }

      it 'returns false' do
        states = { 'excludes' => %w[pending] }
        expect(presenter.can_be_enabled?(states)).to be false
      end
    end

    context 'when the state is not in the excludes list' do
      let(:state) { 'pending' }

      it 'returns true' do
        states = { 'excludes' => %w[completed] }
        expect(presenter.can_be_enabled?(states)).to be true
      end
    end

    context 'when the state is in both the includes and excludes list' do
      let(:state) { 'pending' }

      it 'excludes takes priority' do
        states = { 'includes' => %w[pending], 'excludes' => %w[pending] }
        expect(presenter.can_be_enabled?(states)).to be false
      end
    end
  end
end

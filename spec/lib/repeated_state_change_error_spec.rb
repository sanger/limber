# frozen_string_literal: true

require 'spec_helper'
require './lib/repeated_state_change_error'

RSpec.describe RepeatedStateChangeError do
  let(:exception) { exception_class.new(exception_message) }
  # We're actually testing case equality here, so the cop isn't wanted.
  subject { RepeatedStateChangeError === exception } # rubocop:disable Style/CaseEquality

  context 'A StandardError' do
    let(:exception_class) { StandardError }
    let(:exception_message) { '{"general":["No obvious transition from \"passed\" to \"passed\""]}' }
    it { is_expected.to be false }
  end

  context 'A Sequencescape::Api::ConnectionFactory::Actions::ServerError' do
    let(:exception_class) { Sequencescape::Api::ConnectionFactory::Actions::ServerError }
    context 'with matching states' do
      let(:exception_message) { '{"general":["No obvious transition from \"passed\" to \"passed\""]}' }
      it { is_expected.to be true }
    end
    context 'with different states' do
      let(:exception_message) { '{"general":["No obvious transition from \"exhausted\" to \"passed\""]}' }
      it { is_expected.to be false }
    end
    context 'with completely different message' do
      let(:exception_message) { '{"other":["That didn\'t work"]}' }
      it { is_expected.to be false }
    end
  end
end

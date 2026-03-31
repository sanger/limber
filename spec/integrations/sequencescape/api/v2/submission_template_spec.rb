# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe Sequencescape::Api::V2::SubmissionTemplate do
  describe '::find_by' do
    it 'finds a submission template by uuid' do
      stub_request(:get, 'http://example.com:3000/api/v2/submission_templates').with(
        query: {
          filter: {
            uuid: '7a8029bc-1094-11f1-bb65-16cc5efe8600'
          },
          page: {
            number: 1,
            size: 1
          }
        },
        headers: {
          'Accept' => 'application/vnd.api+json',
          'Content-Type' => 'application/vnd.api+json'
        }
      ).to_return(File.new('./spec/contracts/v2-submission-template-by-uuid.txt'))

      result = described_class.find_by(uuid: '7a8029bc-1094-11f1-bb65-16cc5efe8600')

      expect(result).to be_a described_class
    end
  end
end

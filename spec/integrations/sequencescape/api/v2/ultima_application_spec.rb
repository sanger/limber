# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::UltimaApplication do
  describe '::find_all' do
    subject(:applications) do
      described_class.find_all({ name: ['10x Flex v2'] })
    end

    before do
      stub_request(:get, 'http://example.com:3000/api/v2/ultima_applications')
        .with(
          query: {
            filter: { name: ['10x Flex v2'] },
            include: 'uga_primer,ugb_primer'
          },
          headers: {
            'Accept' => 'application/vnd.api+json',
            'Content-Type' => 'application/vnd.api+json'
          }
        )
        .to_return(
          File.new('./spec/contracts/v2-ultima-applications-by-name.txt')
        )
    end

    it 'finds the applications by name' do
      expect(applications.map(&:name)).to eq(['10x Flex v2'])
    end

    it 'includes the UGA primer' do
      expect(applications.first.uga_primer.name).to eq('UG-CE-tR1')
    end

    it 'includes the UGB primer' do
      expect(applications.first.ugb_primer.name).to eq('UG-srR2')
    end
  end
end

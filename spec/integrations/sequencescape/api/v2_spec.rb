# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2 do
  describe '#merge_page_results' do
    let(:query_builder) do
      # We can't actually use a verified double here as the object doesn't redpond_to? :pages,
      # despite the method actually being implemented. RSpec complains. It is possible that this will
      # be fixed in future versions of JsonApiClient
      double(Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick'), pages: paginator)
    end
    let(:query_builder_page_1) { Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick').page(1) }
    let(:query_builder_page_2) { Sequencescape::Api::V2::Labware.where(purpose_name: 'LTHR Cherrypick').page(2) }
    let(:labware_list_page_1) { create_list :labware, 2 }
    let(:labware_list_page_2) { create_list :labware, 1 }
    let(:paginator) { instance_double(Sequencescape::Api::V2::Base::SequencescapePaginator, total_pages: 2) }

    before do
      allow(query_builder).to receive(:to_a).and_return(labware_list_page_1)
      allow(query_builder).to receive(:page).with(1).and_return(query_builder_page_1)
      allow(query_builder_page_1).to receive(:to_a).and_return(labware_list_page_1)
      allow(query_builder).to receive(:page).with(2).and_return(query_builder_page_2)
      allow(query_builder_page_2).to receive(:to_a).and_return(labware_list_page_2)
    end

    it 'merges page results' do
      expect(described_class.merge_page_results(query_builder)).to eq labware_list_page_1 + labware_list_page_2
    end
  end
end

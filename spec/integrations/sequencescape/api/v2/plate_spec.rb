# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_examples'

RSpec.describe Sequencescape::Api::V2::Plate do
  subject(:plate) { create :v2_plate, barcode_number: 12_345 }

  let(:the_labware) { plate }

  it { is_expected.to be_plate }
  it { is_expected.not_to be_tube }
  it { is_expected.not_to be_tube_rack }

  describe '#stock_plate' do
    let(:stock_plates) { create_list :v2_stock_plate, 2 }
    let(:plate) { build :unmocked_v2_plate, barcode_number: 12_345, ancestors: stock_plates }

    context 'when not a stock_plate' do
      before do
        ancestor_scope = instance_double(JsonApiClient::Query::Builder)
        allow(ancestor_scope).to receive(:order).with(id: :asc).and_return(stock_plates)
        allow(plate).to receive_messages(fetch_stock_plate_ancestors: ancestor_scope, stock_plate?: false)
      end

      it 'returns the last element of the stock plates list' do
        expect(plate.stock_plate).to eq(stock_plates.last)
      end
    end

    context 'when a stock_plate' do
      before { allow(plate).to receive(:stock_plate?).and_return(true) }

      it 'returns itself' do
        expect(plate.stock_plate).to eq(plate)
      end
    end
  end

  describe '#fetch_stock_plate_ancestors' do
    let(:ancestors_scope) { double('ancestors_scope') }
    let(:stock_plate_names) { ['Stock platey plate stock'] }
    let(:stock_plates) { create_list :v2_plate, 2 }

    before do
      allow(plate).to receive(:ancestors).and_return(ancestors_scope)
      allow(SearchHelper).to receive(:stock_plate_names).and_return(stock_plate_names)
      allow(ancestors_scope).to receive(:where).with(purpose_name: stock_plate_names).and_return(stock_plates)
    end

    it 'returns the ancestral stock plates' do
      expect(plate.fetch_stock_plate_ancestors).to eq(stock_plates)
    end
  end

  it_behaves_like 'a labware with a workline identifier'

  describe '#human_barcode' do
    it 'returns the human readable barcode' do
      expect(plate.human_barcode).to eq('DN12345U')
    end
  end

  describe '#labware_barcode' do
    it 'returns a LabwareBarcode' do
      expect(plate.labware_barcode).to be_a LabwareBarcode
    end

    it 'has the correct values' do
      expect(plate.labware_barcode.human).to eq('DN12345U')
      expect(plate.labware_barcode.machine).to eq('DN12345U')

      # TODO: Remove this functionality
      expect(plate.labware_barcode.number).to eq('12345')
      expect(plate.labware_barcode.prefix).to eq('DN')
    end
  end

  describe '::find_by' do
    it 'finds a plate' do
      stub_request(:get, 'http://example.com:3000/api/v2/plates').with(
        query: {
          fields: {
            sample_metadata: 'sample_common_name,collected_by,sample_description',
            submissions: 'lanes_of_sequencing,multiplexed?'
          },
          filter: {
            uuid: '8681e102-b737-11ec-8ace-acde48001122'
          },
          # This is a bit brittle, as it depends on the exact order.
          include: %w[
            purpose
            child_plates.purpose
            wells.qc_results
            wells.downstream_tubes.purpose
            wells.requests_as_source.request_type
            wells.requests_as_source.primer_panel
            wells.requests_as_source.pre_capture_pool
            wells.requests_as_source.submission
            wells.aliquots.sample.sample_metadata
            wells.aliquots.request.request_type
            wells.aliquots.request.primer_panel
            wells.aliquots.request.pre_capture_pool
            wells.aliquots.request.submission
            # wells.aliquots.request.poly_metadata
            wells.transfer_requests_as_target.source_asset
          ].join(',')
        },
        headers: {
          'Accept' => 'application/vnd.api+json',
          'Content-Type' => 'application/vnd.api+json'
        }
      ).to_return(File.new('./spec/contracts/v2-plate-by-uuid-for-presenter.txt'))
      expect(described_class.find_by(uuid: '8681e102-b737-11ec-8ace-acde48001122')).to be_a described_class
    end
  end

  describe '#wells_in_rows' do
    it 'returns wells sorted by rows first and then columns' do
      locations_in_rows = ('A'..'H').flat_map { |letter| (1..12).map { |number| "#{letter}#{number}" } }

      # A1, A2, A3, ..., A12, B1, B2, ..., H10, H11, H12
      expect(plate.wells_in_rows.map(&:location)).to eq(locations_in_rows)
    end
  end

  describe '#wells_in_columns' do
    it 'returns wells sorted by column first and then rows' do
      locations_in_columns = ('1'..'12').flat_map { |number| ('A'..'H').map { |letter| "#{letter}#{number}" } }

      # A1, B1, C1, ..., H1, A2, B2, ..., H2, .. A12, B12, ..., H12
      expect(plate.wells_in_columns.map(&:location)).to eq(locations_in_columns)
    end
  end

  describe '#register_stock_for_plate' do
    let(:plate) { described_class.new(id: '123') }
    let(:url) { "#{described_class.site}/plates/123/register_stock_for_plate" }

    context 'when the request is successful' do
      before do
        stub_request(:post, url).to_return(
          status: 200,
          body: {
            data: {
              type: 'plates',
              id: '123',
              attributes: {
                message: 'Stock successfully registered for plate wells'
              }
            }
          }.to_json,
          headers: {
            'Content-Type' => 'application/json'
          }
        )
      end

      it 'returns a successful response' do
        response = plate.register_stock_for_plate
        expect(response.first.attributes['message']).to match(/Stock successfully registered for plate wells/)
      end
    end

    context 'when the request fails with 422' do
      before do
        stub_request(:post, url).to_return(
          status: 422,
          body: {
            errors: [
              { status: '422', title: 'Stock registration failed', detail: 'Something went wrong during registration.' }
            ]
          }.to_json,
          headers: {
            'Content-Type' => 'application/vnd.api+json'
          }
        )
      end

      it 'returns an error result' do
        response = plate.register_stock_for_plate
        expect(response.errors.first['title']).to match(/Stock registration failed/)
      end
    end
  end
end

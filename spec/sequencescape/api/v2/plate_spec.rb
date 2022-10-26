# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Plate do
  subject(:plate) { create :v2_plate, barcode_number: 12_345 }

  it { is_expected.to be_plate }
  it { is_expected.to_not be_tube }

  describe '#stock_plate' do
    let(:stock_plates) { create_list :v2_stock_plate, 2 }
    let(:plate) { build :unmocked_v2_plate, barcode_number: 12_345, ancestors: stock_plates }

    context 'when not a stock_plate' do
      before do
        ancestor_scope = instance_double('JsonApiClient::Query::Builder')
        expect(plate).to receive(:stock_plates).and_return(ancestor_scope)
        expect(ancestor_scope).to receive(:order).with(id: :asc).and_return(stock_plates)
        expect(plate).to receive(:stock_plate?).and_return(false)
      end

      it 'returns the last element of the stock plates list' do
        expect(plate.stock_plate).to eq(stock_plates.last)
      end
    end

    context 'when a stock_plate' do
      before { expect(plate).to receive(:stock_plate?).and_return(true) }
      it 'returns itself' do
        expect(plate.stock_plate).to eq(plate)
      end
    end
  end

  describe '#stock_plates' do
    let(:ancestors_scope) { double('ancestors_scope') }
    context 'when it is a stock plate' do
      it 'returns [self] if this plate is a stock plate already' do
        allow(plate).to receive(:stock_plate?).and_return(true)
        expect(plate.stock_plates).to eq([plate])
      end
    end
    context 'when it is not a stock plate' do
      let(:stock_plate_names) { ['Stock platey plate stock'] }
      let(:stock_plates) { create_list :v2_plate, 2 }
      before do
        allow(plate).to receive(:ancestors).and_return(ancestors_scope)
        allow(SearchHelper).to receive(:stock_plate_names).and_return(stock_plate_names)
        allow(ancestors_scope).to receive(:where).with(purpose_name: stock_plate_names).and_return(stock_plates)
      end

      it 'returns the stock plates because that must be cool' do
        allow(plate).to receive(:stock_plate?).and_return(false)
        expect(plate.stock_plates).to eq(stock_plates)
      end
    end
  end

  describe '#workline_identifier' do
    it 'displays the barcode of the workline_reference element' do
      plate2 = create :v2_plate
      allow(plate).to receive(:workline_reference).and_return(plate2)
      expect(plate.workline_identifier).to eq(plate2.barcode.human)
    end
    it 'does not break if there is no workline reference' do
      allow(plate).to receive(:workline_reference).and_return(nil)
      expect(plate.workline_identifier).to eq(nil)
    end
  end

  describe '#workline_reference' do
    let(:stock_plate_names) { ['Stock stuff', 'Some other stock stuff'] }
    let(:ancestors_scope) { double('ancestors_scope') }
    before do
      allow(plate).to receive(:ancestors).and_return(ancestors_scope)
      allow(plate).to receive(:stock_plate).and_return(stock_plate)
      allow(SearchHelper).to receive(:stock_plate_names).and_return(stock_plate_names)
      allow(ancestors_scope).to receive(:where).with(purpose_name: stock_plate_names).and_return(stock_plates)
    end

    context 'when the plate has no stock plates' do
      let(:stock_plates) { [] }
      let(:stock_plate) { nil }
      it 'returns nil' do
        expect(plate.workline_reference).to be_nil
      end
    end
    context 'when the plate has one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 1 }
      let(:stock_plate) { stock_plates.last }
      it 'returns the stock plate' do
        expect(plate.workline_reference).to eq(stock_plates.last)
      end
    end
    context 'when the plate has more than one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 2 }
      let(:stock_plate) { stock_plates.last }

      context 'when there are no alternative workline purpose references' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(plate).and_return(nil)
          allow(ancestors_scope).to receive(:where).with(purpose_name: []).and_return([])
        end
        it 'returns the last stock plate' do
          expect(plate.workline_reference).to eq(stock_plates.last)
        end
      end

      context 'when there is a list of alternative workline purpose references' do
        let(:alternative_workline_reference_plates) { create_list :v2_plate, 2 }
        let(:alternative_workline_name) { 'Some other plate with some stuff inside' }

        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name)
            .with(plate)
            .and_return(alternative_workline_name)
          allow(ancestors_scope).to receive(:where)
            .with(purpose_name: alternative_workline_name)
            .and_return(alternative_workline_reference_plates)
        end

        it 'returns the last alternative workline reference' do
          expect(plate.workline_reference).to eq(alternative_workline_reference_plates.last)
        end
      end
    end
  end

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
      stub_request(:get, 'http://example.com:3000/api/v2/plates')
        .with(
          query: {
            fields: {
              sample_metadata: 'sample_common_name,collected_by',
              submissions: 'lanes_of_sequencing'
            },
            filter: {
              uuid: '8681e102-b737-11ec-8ace-acde48001122'
            },
            # This is a bit brittle, as it depends on the exact order.
            include:
              'purpose,child_plates.purpose,wells.downstream_tubes.purpose,' \
                'wells.requests_as_source.request_type,wells.requests_as_source.primer_panel,' \
                'wells.requests_as_source.pre_capture_pool,wells.requests_as_source.submission,' \
                'wells.aliquots.sample.sample_metadata,wells.aliquots.request.request_type,' \
                'wells.aliquots.request.primer_panel,wells.aliquots.request.pre_capture_pool,' \
                'wells.aliquots.request.submission'
          },
          headers: {
            'Accept' => 'application/vnd.api+json',
            'Content-Type' => 'application/vnd.api+json'
          }
        )
        .to_return(File.new('./spec/contracts/v2-plate-by-uuid-for-presenter.txt'))
      expect(
        Sequencescape::Api::V2::Plate.find_by(uuid: '8681e102-b737-11ec-8ace-acde48001122')
      ).to be_a Sequencescape::Api::V2::Plate
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

class SomeStockPlates
  def initialize(stock_plates)
    @stock_plates = stock_plates
  end

  def where(_arg)
    @stock_plates
  end
end

RSpec.describe Sequencescape::Api::V2::Tube do
  subject(:tube) { create :v2_tube, barcode_number: 12_345 }

  it { is_expected.to_not be_plate }
  it { is_expected.to be_tube }

  describe '#stock plate' do
    let(:stock_plates) { create_list(:v2_stock_plate, 4) }
    let(:tube_with_ancestors) { create :v2_tube, barcode_number: 12_345, ancestors: stock_plates }

    # I know this is a real hack but all we need to know is whether
    # it returns the last stock plate
    # I am not going to fumble about trying to recreate the whole pipeline
    it 'should return the last plate' do
      allow(tube_with_ancestors).to receive(:ancestors).and_return(SomeStockPlates.new(stock_plates))
      expect(tube_with_ancestors.stock_plate).to eq(stock_plates.last)
    end
  end

  describe '#workline_identifier' do
    it 'displays the barcode of the workline_reference element' do
      tube1 = create :v2_tube
      allow(tube).to receive(:workline_reference).and_return(tube1)
      expect(tube.workline_identifier).to eq(tube1.barcode.human)
    end

    it 'does not break if there is no workline reference' do
      allow(tube).to receive(:workline_reference).and_return(nil)
      expect(tube.workline_identifier).to eq(nil)
    end
  end

  describe '#workline_reference' do
    let(:stock_plate_names) { ['Stock stuff', 'Some other stock stuff'] }
    let(:ancestors_scope) { double('ancestors_scope') }
    before do
      allow(tube).to receive(:ancestors).and_return(ancestors_scope)
      allow(tube).to receive(:stock_plate).and_return(stock_plate)
      allow(SearchHelper).to receive(:stock_plate_names).and_return(stock_plate_names)
      allow(ancestors_scope).to receive(:where).with(purpose_name: stock_plate_names).and_return(stock_plates)
    end

    context 'when the plate has no stock plates' do
      let(:stock_plates) { [] }
      let(:stock_plate) { nil }
      it 'returns nil' do
        expect(tube.workline_reference).to be_nil
      end
    end
    context 'when the plate has one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 1 }
      let(:stock_plate) { stock_plates.last }
      it 'returns the stock plate' do
        expect(tube.workline_reference).to eq(stock_plates.last)
      end
    end
    context 'when the plate has more than one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 2 }
      let(:stock_plate) { stock_plates.last }

      context 'when there are no alternative workline purpose references' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(tube).and_return(nil)
          allow(ancestors_scope).to receive(:where).with(purpose_name: []).and_return([])
        end
        it 'returns the last stock plate' do
          expect(tube.workline_reference).to eq(stock_plates.last)
        end
      end

      context 'when there is a list of alternative workline purpose references' do
        let(:alternative_workline_reference_plates) { create_list :v2_plate, 2 }
        let(:alternative_workline_name) { 'Some other plate with some stuff inside' }

        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name)
            .with(tube)
            .and_return(alternative_workline_name)
          allow(ancestors_scope).to receive(:where)
            .with(purpose_name: alternative_workline_name)
            .and_return(alternative_workline_reference_plates)
        end

        it 'returns the last alternative workline reference' do
          expect(tube.workline_reference).to eq(alternative_workline_reference_plates.last)
        end
      end
    end
  end
end

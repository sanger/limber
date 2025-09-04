# frozen_string_literal: true

RSpec.shared_examples 'a labware with a workline identifier' do
  describe '#workline_identifier' do
    it 'displays the barcode of the workline_reference element' do
      plate2 = create :v2_plate
      allow(the_labware).to receive(:workline_reference).and_return(plate2)
      expect(the_labware.workline_identifier).to eq(plate2.barcode.human)
    end

    it 'does not break if there is no workline reference' do
      allow(the_labware).to receive(:workline_reference).and_return(nil)
      expect(the_labware.workline_identifier).to be_nil
    end
  end

  describe '#workline_reference' do
    let(:stock_plate_names) { ['Stock stuff', 'Some other stock stuff'] }
    let(:ancestors_scope) { double('ancestors_scope') }

    before do
      allow(ancestors_scope).to receive(:where).with(purpose_name: stock_plate_names).and_return(stock_plates)
      allow(the_labware).to receive_messages(ancestors: ancestors_scope, stock_plate: stock_plate)
      allow(SearchHelper).to receive(:stock_plate_names).and_return(stock_plate_names)
    end

    context 'when the plate has no stock plates' do
      let(:stock_plates) { [] }
      let(:stock_plate) { nil }

      it 'returns nil' do
        expect(the_labware.workline_reference).to be_nil
      end
    end

    context 'when the plate has one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 1 }
      let(:stock_plate) { stock_plates.last }

      it 'returns the stock plate' do
        expect(the_labware.workline_reference).to eq(stock_plates.last)
      end
    end

    context 'when the plate has more than one stock plate' do
      let(:stock_plates) { create_list :v2_plate, 2 }
      let(:stock_plate) { stock_plates.last }

      context 'when there are no alternative workline purpose references' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(the_labware).and_return(nil)
          allow(ancestors_scope).to receive(:where).with(purpose_name: []).and_return([])
        end

        it 'returns the last stock plate' do
          expect(the_labware.workline_reference).to eq(stock_plates.last)
        end
      end

      context 'when there is a list of alternative workline purpose references' do
        let(:alternative_workline_reference_plates) { create_list :v2_plate, 2 }
        let(:alternative_workline_name) { 'Some other plate with some stuff inside' }

        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(the_labware).and_return(
            alternative_workline_name
          )
          allow(ancestors_scope).to receive(:where).with(purpose_name: alternative_workline_name).and_return(
            alternative_workline_reference_plates
          )
        end

        it 'returns the last alternative workline reference' do
          expect(the_labware.workline_reference).to eq(alternative_workline_reference_plates.last)
        end
      end
    end
  end
end

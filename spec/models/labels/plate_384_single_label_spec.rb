# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::Plate384SingleLabel, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the label of a plate' do
    let(:labware) { build :plate, size: 384 }
    let(:label) { described_class.new(labware) }
    let(:date_format) { /\A\s?\d{1,2}-[A-Z]{3}-\d{4}\z/ } # e.g., ' 4 JUL 2023' or '24 JUL 2023'

    before do
      create :stock_plate_config
      allow(label).to receive(:first_of_last_purpose).and_return(labware.stock_plate)
    end

    describe '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to match(date_format)
        expect(attributes[:bottom_left]).to eq labware.barcode.human
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq labware.purpose_name
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end

    describe '#sprint_attributes' do
      it 'has the correct attributes' do
        attributes = label.sprint_attributes
        expect(attributes[:top_left]).to match(date_format)
        expect(attributes[:bottom_left]).to eq(labware.barcode.human)
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq labware.purpose_name
        expect(attributes[:barcode]).to eq labware.barcode.human
      end
    end
  end

  describe '#first_of_configured_purpose' do
    let(:labware) { create :v2_plate, purpose_name: 'Plate Purpose', barcode_number: '123' }
    let(:label) { described_class.new(labware) }
    let(:ancestor1) { create :v2_plate, purpose_name: 'Purpose1', barcode_number: '456' }
    let(:ancestor2) { create :v2_plate, purpose_name: 'Purpose2', barcode_number: '789' }
    let(:ancestor3) { create :v2_plate, purpose_name: 'Purpose3', barcode_number: '101' }

    before do
      # Use a more direct approach by stubbing the actual method rather than trying to mock the relation
      allow(SearchHelper).to receive(:alternative_workline_reference_name)

      # Stub the individual where calls with their results
      # rubocop:disable RSpec/MessageChain
      allow(labware).to receive_message_chain(:ancestors, :where).with(purpose_name: 'Purpose1').and_return([ancestor1])
      allow(labware).to receive_message_chain(:ancestors, :where).with(purpose_name: 'Purpose2').and_return([ancestor2])
      allow(labware).to receive_message_chain(:ancestors, :where).with(purpose_name: 'Purpose3').and_return([ancestor3])
      allow(labware).to receive_message_chain(:ancestors, :where).with(purpose_name: 'NonExistentPurpose').and_return(
        []
      )
      allow(labware).to receive_message_chain(:ancestors, :where).with(purpose_name: 'AlsoNonExistent').and_return([])
      # rubocop:enable RSpec/MessageChain
    end

    context 'when alternative_workline_identifier_purpose is blank' do
      before { allow(SearchHelper).to receive(:alternative_workline_reference_name).with(labware).and_return(nil) }

      it 'returns nil' do
        expect(label.send(:first_of_configured_purpose)).to be_nil
      end
    end

    context 'when alternative_workline_identifier_purpose is a string' do
      before do
        allow(SearchHelper).to receive(:alternative_workline_reference_name).with(labware).and_return('Purpose2')
      end

      it 'returns the first ancestor with the matching purpose name' do
        expect(label.send(:first_of_configured_purpose)).to eq(ancestor2)
      end
    end

    context 'when alternative_workline_identifier_purpose is an array' do
      context 'when the first purpose in the array is found' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(labware).and_return(
            %w[Purpose1 Purpose2]
          )
        end

        it 'returns the first matching ancestor' do
          expect(label.send(:first_of_configured_purpose)).to eq(ancestor1)
        end
      end

      context 'when only the second purpose in the array is found' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(labware).and_return(
            %w[NonExistentPurpose Purpose3]
          )
        end

        it 'returns the matching ancestor' do
          expect(label.send(:first_of_configured_purpose)).to eq(ancestor3)
        end
      end

      context 'when no purpose in the array is found' do
        before do
          allow(SearchHelper).to receive(:alternative_workline_reference_name).with(labware).and_return(
            %w[NonExistentPurpose AlsoNonExistent]
          )
        end

        it 'returns nil' do
          expect(label.send(:first_of_configured_purpose)).to be_nil
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/tag_transfer_picklist.csv.erb' do
  let(:tag_group) { create(:tag_group, name: 'Ultima P1') }
  let(:tag) { create(:tag, tag_group:) }
  let(:indices) { [1, 8, 9, 10, 96] }
  let(:wells) do
    indices.each_with_index.map do |index, position|
      aliquot = create(:aliquot, tag: tag, tag_index: index, tag2: nil)
      create(:well, location: "#{('A'.ord + position).chr}1", aliquots: [aliquot, aliquot])
    end
  end
  let(:plate) { create(:plate, wells:) }

  before { assign(:plate, plate) }

  it 'maps saved indices in column order without duplicating pooled aliquot transfers' do
    expect(CSV.parse(render)).to eq(
      [
        ['Tag Set', 'Tag Plate Well', 'Destination Barcode', 'Destination Well'],
        ['Ultima P1', 'A1', plate.labware_barcode.human, 'A1'],
        ['Ultima P1', 'H1', plate.labware_barcode.human, 'B1'],
        ['Ultima P1', 'A2', plate.labware_barcode.human, 'C1'],
        ['Ultima P1', 'B2', plate.labware_barcode.human, 'D1'],
        ['Ultima P1', 'H12', plate.labware_barcode.human, 'E1']
      ]
    )
  end

  context 'with an empty well' do
    let(:wells) { [create(:well, location: 'A1', aliquots: [])] }

    it 'outputs only the header' do
      expect(CSV.parse(render)).to eq([['Tag Set', 'Tag Plate Well', 'Destination Barcode', 'Destination Well']])
    end
  end

  context 'with a second tag group' do
    let(:second_tag) { create(:tag, tag_group: create(:tag_group, name: 'Ultima P2')) }
    let(:wells) do
      aliquot = create(:aliquot, tag: tag, tag_index: 13, tag2: second_tag, tag2_index: 24)
      [create(:well, location: 'C3', aliquots: [aliquot])]
    end

    it 'outputs a transfer for each source tag group' do
      expect(CSV.parse(render).drop(1)).to eq(
        [
          ['Ultima P1', 'E2', plate.labware_barcode.human, 'C3'],
          ['Ultima P2', 'H3', plate.labware_barcode.human, 'C3']
        ]
      )
    end
  end

  [nil, 0, 97].each do |invalid_index|
    context "with tag index #{invalid_index.inspect}" do
      let(:indices) { [invalid_index] }

      it 'rejects an invalid source location' do
        expect { render }.to raise_error(ActionView::Template::Error, /Invalid tag index/)
      end
    end
  end

  context 'without a saved tag' do
    let(:tag) { nil }

    it 'rejects an untagged occupied well' do
      expect { render }.to raise_error(ActionView::Template::Error, /Missing tag for destination well/)
    end
  end
end

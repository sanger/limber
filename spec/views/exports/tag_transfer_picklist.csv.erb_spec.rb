# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/tag_transfer_picklist.csv.erb' do
  let(:tag_group) { create(:tag_group, name: 'Ultima P1') }
  let(:tag) { create(:tag, tag_group:) }
  let(:offset) { 2 }
  let(:indices) { (1..9).map { |index| index + offset } }
  let(:wells) do
    indices.each_with_index.map do |index, position|
      aliquot = create(:aliquot, tag: tag, tag_index: index, tag2: nil)
      create(:well, location: WellHelpers.column_order(96).fetch(position), aliquots: [aliquot, aliquot])
    end
  end
  let(:plate) { create(:plate, wells:) }

  before { assign(:plate, plate) }

  it 'maps saved tags with offset 2 in column order without duplicating pooled aliquot transfers' do
    expect(CSV.parse(render)).to eq(
      [
        ['Tag Set', 'Tag Plate Well', 'Destination Barcode', 'Destination Well'],
        ['Ultima P1', 'C1', plate.labware_barcode.human, 'A1'],
        ['Ultima P1', 'D1', plate.labware_barcode.human, 'B1'],
        ['Ultima P1', 'E1', plate.labware_barcode.human, 'C1'],
        ['Ultima P1', 'F1', plate.labware_barcode.human, 'D1'],
        ['Ultima P1', 'G1', plate.labware_barcode.human, 'E1'],
        ['Ultima P1', 'H1', plate.labware_barcode.human, 'F1'],
        ['Ultima P1', 'A2', plate.labware_barcode.human, 'G1'],
        ['Ultima P1', 'B2', plate.labware_barcode.human, 'H1'],
        ['Ultima P1', 'C2', plate.labware_barcode.human, 'A2']
      ]
    )
  end

  context 'without a saved tag' do
    let(:tag) { nil }

    it 'rejects an untagged occupied well' do
      expect { render }.to raise_error(ActionView::Template::Error, /Missing tag for destination well/)
    end
  end
end

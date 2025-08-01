# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/cardinal_tagging_csv_for_custom_pooling.csv.erb' do
  let(:aliquot_1) { create :v2_tagged_aliquot }
  let(:aliquot_2) { create :v2_tagged_aliquot }
  let(:aliquot_3) { create :v2_tagged_aliquot }
  let(:well_a1) { create(:v2_tagged_well, position: { 'name' => 'A1' }, aliquots: [aliquot_1, aliquot_3]) }
  let(:well_b1) { create(:v2_tagged_well, position: { 'name' => 'B1' }, aliquots: [aliquot_2]) }
  let(:labware) { create(:v2_plate, wells: [well_a1, well_b1]) }

  before { assign(:plate, labware) }

  let(:expected_headers) do
    ['Source Well', 'Volume to add to pool', 'Dest. well', 'Number of samples', 'Tag index', 'Tag 2 index']
  end

  def get_column(csv, index)
    csv[1..].pluck(index)
  end

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render)
    expect(parsed_csv.size).to eq 3
    expect(parsed_csv[0]).to eq expected_headers

    # Check one column at a time
    expect(get_column(parsed_csv, 0)).to eq(%w[A1 B1])
    expect(get_column(parsed_csv, 1)).to eq([nil, nil])
    expect(get_column(parsed_csv, 2)).to eq([nil, nil])

    expect(get_column(parsed_csv, 3)).to eq(%w[2 1])

    expect(get_column(parsed_csv, 4)).to eq([well_a1.aliquots[0].tag_index.to_s, well_b1.aliquots[0].tag_index.to_s])
    expect(get_column(parsed_csv, 5)).to eq([well_a1.aliquots[0].tag2_index.to_s, well_b1.aliquots[0].tag2_index.to_s])
  end

  context "well a1's aliquot has no tags" do
    let(:aliquot) { create(:v2_aliquot) }
    let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, aliquots: [aliquot]) }

    it "gives nil values for a1's tag indices", :aggregate_failures do
      parsed_csv = CSV.parse(render)
      expect(parsed_csv.size).to eq 3
      expect(parsed_csv[0]).to eq expected_headers

      expect(get_column(parsed_csv, 0)).to eq(%w[A1 B1])
      expect(get_column(parsed_csv, 1)).to eq([nil, nil])
      expect(get_column(parsed_csv, 2)).to eq([nil, nil])
      expect(get_column(parsed_csv, 3)).to all(satisfy { |val| val.match(/^\d+$/) })
      expect(get_column(parsed_csv, 4)).to eq([nil, well_b1.aliquots[0].tag_index.to_s])
      expect(get_column(parsed_csv, 5)).to eq([nil, well_b1.aliquots[0].tag2_index.to_s])
    end
  end

  context 'well a1 is empty' do
    let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, aliquot_count: 0) }

    it 'skips empty wells', :aggregate_failures do
      parsed_csv = CSV.parse(render)
      expect(parsed_csv.size).to eq 2
      expect(parsed_csv[0]).to eq expected_headers

      expect(get_column(parsed_csv, 0)).to eq(['B1'])
      expect(get_column(parsed_csv, 1)).to eq([nil])
      expect(get_column(parsed_csv, 2)).to eq([nil])
      expect(get_column(parsed_csv, 3)).to all(satisfy { |val| val.match(/^\d+$/) })
      expect(get_column(parsed_csv, 4)).to eq([well_b1.aliquots[0].tag_index.to_s])
      expect(get_column(parsed_csv, 5)).to eq([well_b1.aliquots[0].tag2_index.to_s])
    end
  end

  context 'well a1 has more than 1 aliquot but with matching tag indices' do
    let(:well_a1) do
      create(:v2_well, position: { 'name' => 'A1' }, aliquot_count: 2, aliquot_factory: :v2_tagged_aliquot)
    end

    it 'includes all wells, still', :aggregate_failures do
      parsed_csv = CSV.parse(render)
      expect(parsed_csv.size).to eq 3
      expect(parsed_csv[0]).to eq expected_headers

      expect(get_column(parsed_csv, 0)).to eq(%w[A1 B1])
      expect(get_column(parsed_csv, 1)).to eq([nil, nil])
      expect(get_column(parsed_csv, 2)).to eq([nil, nil])
      expect(get_column(parsed_csv, 3)).to all(satisfy { |val| val.match(/^\d+$/) })
      expect(get_column(parsed_csv, 4)).to eq([well_a1.aliquots[0].tag_index.to_s, well_b1.aliquots[0].tag_index.to_s])
      expect(get_column(parsed_csv, 5)).to eq(
        [well_a1.aliquots[0].tag2_index.to_s, well_b1.aliquots[0].tag2_index.to_s]
      )
    end
  end

  context 'well a1 has more than 1 aliquot with different tag_index values' do
    let(:aliquot_1) { create(:v2_aliquot, tag_oligo: 'CAT', tag_index: 5, tag2_oligo: 'GAG', tag2_index: 10) }
    let(:aliquot_2) { create(:v2_aliquot, tag_oligo: 'TAT', tag_index: 7, tag2_oligo: 'GAG', tag2_index: 10) }
    let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, aliquots: [aliquot_1, aliquot_2]) }

    it 'does not include well a1 in the CSV file', :aggregate_failures do
      parsed_csv = CSV.parse(render)
      expect(parsed_csv.size).to eq 2
      expect(parsed_csv[0]).to eq expected_headers

      expect(get_column(parsed_csv, 0)).to eq(['B1'])
      expect(get_column(parsed_csv, 1)).to eq([nil])
      expect(get_column(parsed_csv, 2)).to eq([nil])
      expect(get_column(parsed_csv, 3)).to all(satisfy { |val| val.match(/^\d+$/) })
      expect(get_column(parsed_csv, 4)).to eq([well_b1.aliquots[0].tag_index.to_s])
      expect(get_column(parsed_csv, 5)).to eq([well_b1.aliquots[0].tag2_index.to_s])
    end
  end

  context 'well a1 has more than 1 aliquot with different tag2_index values' do
    let(:aliquot_1) { create(:v2_aliquot, tag_oligo: 'CAT', tag_index: 5, tag2_oligo: 'GAG', tag2_index: 10) }
    let(:aliquot_2) { create(:v2_aliquot, tag_oligo: 'CAT', tag_index: 5, tag2_oligo: 'TAC', tag2_index: 8) }
    let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, aliquots: [aliquot_1, aliquot_2]) }

    it 'does not include well a1 in the CSV file', :aggregate_failures do
      parsed_csv = CSV.parse(render)
      expect(parsed_csv.size).to eq 2
      expect(parsed_csv[0]).to eq expected_headers

      expect(get_column(parsed_csv, 0)).to eq(['B1'])
      expect(get_column(parsed_csv, 1)).to eq([nil])
      expect(get_column(parsed_csv, 2)).to eq([nil])
      expect(get_column(parsed_csv, 3)).to all(satisfy { |val| val.match(/^\d+$/) })
      expect(get_column(parsed_csv, 4)).to eq([well_b1.aliquots[0].tag_index.to_s])
      expect(get_column(parsed_csv, 5)).to eq([well_b1.aliquots[0].tag2_index.to_s])
    end
  end
end

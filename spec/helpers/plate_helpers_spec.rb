# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PlateHelper do
  include PlateHelper

  let(:pool) do
    { 'pool1' => { 'wells' => %w[C3 D1 D2 D3 E1 E2 E3 F1 F2 F3 G1 G2 G3 H1 H2 H3 A1 A2 A3 B1 B2 B3 C1 C2] },
      'pool2' => { 'wells' => %w[E7 F6 G6 H6 A7 B7 C7 D7 E6] },
      'pool3' => { 'wells' => %w[C6 D4 D5 D6 E4 E5 F4 F5 G4 A4 A5 A6 B4 B5 B6 C4 C5 G5 H4 H5] } }
  end

  it 'orders pools by their correct id' do
    pools = pools_by_id(pool)
    expect(pools['A1']).to eq(1)
    expect(pools['D3']).to eq(1)
    expect(pools['A7']).to eq(3)
    expect(pools['H6']).to eq(3)
    expect(pools['A4']).to eq(2)
    expect(pools['H4']).to eq(2)
  end
end

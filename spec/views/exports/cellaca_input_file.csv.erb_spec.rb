# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/cellaca_input_file.csv.erb', type: :view do
  context 'with a full plate' do
    let(:labware) { create(:v2_plate, barcode_number: 1) }

    before do
      assign(:plate, labware)
      assign(:page, page)
    end

    context 'when page is 0' do
      let(:page) { 0 }
      let(:expected_content) do
        [
          %w[DN1S:A1 DN1S:A2 DN1S:A3],
          %w[DN1S:B1 DN1S:B2 DN1S:B3],
          %w[DN1S:C1 DN1S:C2 DN1S:C3],
          %w[DN1S:D1 DN1S:D2 DN1S:D3],
          %w[DN1S:E1 DN1S:E2 DN1S:E3],
          %w[DN1S:F1 DN1S:F2 DN1S:F3],
          %w[DN1S:G1 DN1S:G2 DN1S:G3],
          %w[DN1S:H1 DN1S:H2 DN1S:H3]
        ]
      end

      it 'renders the expected content' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end

    context 'when page is 1' do
      let(:page) { 1 }
      let(:expected_content) do
        [
          %w[DN1S:A4 DN1S:A5 DN1S:A6],
          %w[DN1S:B4 DN1S:B5 DN1S:B6],
          %w[DN1S:C4 DN1S:C5 DN1S:C6],
          %w[DN1S:D4 DN1S:D5 DN1S:D6],
          %w[DN1S:E4 DN1S:E5 DN1S:E6],
          %w[DN1S:F4 DN1S:F5 DN1S:F6],
          %w[DN1S:G4 DN1S:G5 DN1S:G6],
          %w[DN1S:H4 DN1S:H5 DN1S:H6]
        ]
      end

      it 'renders the expected content' do
        expect(CSV.parse(render)).to eq(expected_content)
      end
    end
  end
end

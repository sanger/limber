# frozen_string_literal: true

require 'spec_helper'
require 'well_helpers'

WELL_96 = %w[
  A1 B1 C1 D1 E1 F1 G1 H1
  A2 B2 C2 D2 E2 F2 G2 H2
  A3 B3 C3 D3 E3 F3 G3 H3
  A4 B4 C4 D4 E4 F4 G4 H4
  A5 B5 C5 D5 E5 F5 G5 H5
  A6 B6 C6 D6 E6 F6 G6 H6
  A7 B7 C7 D7 E7 F7 G7 H7
  A8 B8 C8 D8 E8 F8 G8 H8
  A9 B9 C9 D9 E9 F9 G9 H9
  A10 B10 C10 D10 E10 F10 G10 H10
  A11 B11 C11 D11 E11 F11 G11 H11
  A12 B12 C12 D12 E12 F12 G12 H12
].freeze

WELL_384 = %w[
  A1 B1 C1 D1 E1 F1 G1 H1 I1 J1 K1 L1 M1 N1 O1 P1
  A2 B2 C2 D2 E2 F2 G2 H2 I2 J2 K2 L2 M2 N2 O2 P2
  A3 B3 C3 D3 E3 F3 G3 H3 I3 J3 K3 L3 M3 N3 O3 P3
  A4 B4 C4 D4 E4 F4 G4 H4 I4 J4 K4 L4 M4 N4 O4 P4
  A5 B5 C5 D5 E5 F5 G5 H5 I5 J5 K5 L5 M5 N5 O5 P5
  A6 B6 C6 D6 E6 F6 G6 H6 I6 J6 K6 L6 M6 N6 O6 P6
  A7 B7 C7 D7 E7 F7 G7 H7 I7 J7 K7 L7 M7 N7 O7 P7
  A8 B8 C8 D8 E8 F8 G8 H8 I8 J8 K8 L8 M8 N8 O8 P8
  A9 B9 C9 D9 E9 F9 G9 H9 I9 J9 K9 L9 M9 N9 O9 P9
  A10 B10 C10 D10 E10 F10 G10 H10 I10 J10 K10 L10 M10 N10 O10 P10
  A11 B11 C11 D11 E11 F11 G11 H11 I11 J11 K11 L11 M11 N11 O11 P11
  A12 B12 C12 D12 E12 F12 G12 H12 I12 J12 K12 L12 M12 N12 O12 P12
  A13 B13 C13 D13 E13 F13 G13 H13 I13 J13 K13 L13 M13 N13 O13 P13
  A14 B14 C14 D14 E14 F14 G14 H14 I14 J14 K14 L14 M14 N14 O14 P14
  A15 B15 C15 D15 E15 F15 G15 H15 I15 J15 K15 L15 M15 N15 O15 P15
  A16 B16 C16 D16 E16 F16 G16 H16 I16 J16 K16 L16 M16 N16 O16 P16
  A17 B17 C17 D17 E17 F17 G17 H17 I17 J17 K17 L17 M17 N17 O17 P17
  A18 B18 C18 D18 E18 F18 G18 H18 I18 J18 K18 L18 M18 N18 O18 P18
  A19 B19 C19 D19 E19 F19 G19 H19 I19 J19 K19 L19 M19 N19 O19 P19
  A20 B20 C20 D20 E20 F20 G20 H20 I20 J20 K20 L20 M20 N20 O20 P20
  A21 B21 C21 D21 E21 F21 G21 H21 I21 J21 K21 L21 M21 N21 O21 P21
  A22 B22 C22 D22 E22 F22 G22 H22 I22 J22 K22 L22 M22 N22 O22 P22
  A23 B23 C23 D23 E23 F23 G23 H23 I23 J23 K23 L23 M23 N23 O23 P23
  A24 B24 C24 D24 E24 F24 G24 H24 I24 J24 K24 L24 M24 N24 O24 P24
].freeze

RSpec.describe WellHelpers do
  let(:well_96) { WELL_96 }
  let(:stamp_96) { WELL_96.zip(WELL_96).to_h }

  let(:well_384) { WELL_384 }
  let(:stamp_384) { WELL_384.zip(WELL_384).to_h }

  shared_examples 'range generator' do
    it 'generates ranges' do
      expect(described_class.formatted_range(wells, size)).to eq(range)
    end
  end

  context 'Full plate' do
    let(:wells) { described_class.column_order }
    let(:size) { 96 }
    let(:range) { 'A1-H12' }

    it_behaves_like 'range generator'
  end

  context 'Partial plate' do
    let(:wells) { described_class.column_order.slice(0, 12) }
    let(:size) { 96 }
    let(:range) { 'A1-D2' }

    it_behaves_like 'range generator'
  end

  context 'Split pool' do
    let(:wells) { %w[A1 B1 C1 F1 G1 H1 A2 C10 F10 G10] }
    let(:size) { 96 }
    let(:range) { 'A1-C1, F1-A2, C10, F10-G10' }

    it_behaves_like 'range generator'
  end

  context 'Unordered pool' do
    let(:wells) { %w[A1 F10 F1 B1 C1 G1 H1 A2 C10 G10] }
    let(:size) { 96 }
    let(:range) { 'A1-C1, F1-A2, C10, F10-G10' }

    it_behaves_like 'range generator'
  end

  context '384 well plate' do
    let(:wells) { WELL_384 }
    let(:size) { 384 }
    let(:range) { 'A1-P24' }

    it_behaves_like 'range generator'
  end

  describe '::column_order' do
    context 'by default' do
      subject { described_class.column_order }

      it { is_expected.to eq(well_96) }
    end

    context 'with a specified size' do
      subject { described_class.column_order(size) }

      context 'of 96' do
        let(:size) { 96 }

        it { is_expected.to eq(well_96) }
      end

      context 'of 384' do
        let(:size) { 384 }

        it { is_expected.to eq(well_384) }
      end
    end
  end

  describe '::stamp_hash' do
    subject { described_class.stamp_hash(size) }

    context '96' do
      let(:size) { 96 }

      it { is_expected.to eq(stamp_96) }
    end

    context '384' do
      let(:size) { 384 }

      it { is_expected.to eq(stamp_384) }
    end
  end

  describe('::index_of') do
    context 'by default' do
      subject { described_class.index_of(well) }

      WELL_96.each_with_index do |test_well, test_index|
        context("well #{test_well}") do
          let(:well) { test_well }

          it { is_expected.to eq(test_index) }
        end
      end
    end

    context 'with a specified size' do
      subject { described_class.index_of(well, size) }

      context 'of 96' do
        let(:size) { 96 }

        WELL_96.each_with_index do |test_well, test_index|
          context("well #{test_well}") do
            let(:well) { test_well }

            it { is_expected.to eq(test_index) }
          end
        end
      end

      context 'of 384' do
        let(:size) { 384 }

        WELL_384.each_with_index do |test_well, test_index|
          context("well #{test_well}") do
            let(:well) { test_well }

            it { is_expected.to eq(test_index) }
          end
        end
      end
    end
  end

  describe ':well_name' do
    subject { described_class.well_name(row, column) }

    context 'A1' do
      let(:row) { 0 }
      let(:column) { 0 }

      it { is_expected.to eq('A1') }
    end

    context 'H12' do
      let(:row) { 7 }
      let(:column) { 11 }

      it { is_expected.to eq('H12') }
    end

    context 'P24' do
      let(:row) { 15 }
      let(:column) { 23 }

      it { is_expected.to eq('P24') }
    end
  end
end

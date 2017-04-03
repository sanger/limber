# frozen_string_literal: true

require 'spec_helper'
require 'well_helpers'

describe WellHelpers do
  shared_examples 'range generator' do
    it 'generates ranges' do
      expect(WellHelpers.formatted_range(wells)).to eq(range)
    end
  end

  context 'Full plate' do
    let(:wells) { WellHelpers.column_order }
    let(:range) { 'A1-H12' }
    it_behaves_like 'range generator'
  end

  context 'Partial plate' do
    let(:wells) { WellHelpers.column_order.slice(0, 12) }
    let(:range) { 'A1-D2' }
    it_behaves_like 'range generator'
  end

  context 'Split pool' do
    let(:wells) { %w(A1 B1 C1 F1 G1 H1 A2 C10 F10 G10) }
    let(:range) { 'A1-C1, F1-A2, C10, F10-G10' }
    it_behaves_like 'range generator'
  end

  context 'Unordered pool' do
    let(:wells) { %w(A1 F10 F1 B1 C1 G1 H1 A2 C10 G10) }
    let(:range) { 'A1-C1, F1-A2, C10, F10-G10' }
    it_behaves_like 'range generator'
  end
end

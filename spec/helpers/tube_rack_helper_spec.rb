# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TubeRackHelper do
  include described_class

  describe '::racked_tube_tooltip' do
    let(:tube) { build(:tube, name: 'tube-name', labware_barcode: 'tube-barcode') }
    let(:location) { 'A1' }

    it 'returns the location and tube name and barcode' do
      expect(racked_tube_tooltip(tube, location)).to eq(
        "A1: example-purpose #{tube.name} #{tube.labware_barcode.human}"
      )
    end

    it 'returns the location if tube is nil' do
      expect(racked_tube_tooltip(nil, location)).to eq(location)
    end
  end
end

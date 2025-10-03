# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Exports::FilenameHandler::UltimaRebalancing do
  let(:aliquot1_pm1) { build :poly_metadatum, key: 'batch_id', value: 'batch_id_1' }
  let(:aliquot2_pm1) { build :poly_metadatum, key: 'batch_id', value: 'batch_id_1' }

  let(:labware) do
    t = build(
      :tube,
      aliquot_count: 2
    )
    t.aliquots[0].poly_metadata = [aliquot1_pm1]
    t.aliquots[1].poly_metadata = [aliquot2_pm1]
    t
  end
  # These arent used but are passed in to keep the build_filename signature the same
  let(:filename) { nil }
  let(:page) { nil }
  let(:export) { nil }

  context 'when the labware has aliquots with batch_id polymetadata' do
    it 'returns the batch_id as the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq(aliquot1_pm1.value)
    end
  end

  context 'when the labware has aliquots with differing batch_id polymetadata' do
    before do
      aliquot1_pm1.value = 'batch_id_2'
    end

    it 'returns the batch_ids as a list as the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("#{aliquot1_pm1.value}_#{aliquot2_pm1.value}")
    end
  end

  context 'when the labware has aliquots with no batch_id polymetadata' do
    before do
      aliquot1_pm1.value = nil
      aliquot2_pm1.value = nil
    end

    it 'returns the batch_id as the filename' do
      result = described_class.build_filename(filename, labware, page, export)
      expect(result).to eq("Ultima_Rebalancing_#{labware.barcode.human}")
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  let(:yaml) do
    '
        Plate with holes:
          :name: "Plate with holes"
          :asset_type: "plate"

        Plate with more holes:
          :name: "Plate with more holes"
          :asset_type: "plate"
          :alternative_workline_identifier: Plate with holes
    '
  end

  let(:data) do
    YAML
      .safe_load(yaml, [Symbol])
      .each_with_object({}) do |list, memo|
        k, v = list
        memo[k] = OpenStruct.new(v) # rubocop:todo Style/OpenStructUse
        memo
      end
  end

  before { allow(Settings).to receive(:purposes).and_return(data) }

  context '#purpose_config_for_purpose_name' do
    it 'returns the purpose config from the purposes file' do
      conf = SearchHelper.purpose_config_for_purpose_name('Plate with holes')
      expect(conf[:name]).to eq('Plate with holes')
    end
    it 'returns nil if it cannot find the purpose' do
      conf = SearchHelper.purpose_config_for_purpose_name('Plate without holes')
      expect(conf).to be_nil
    end
  end
  context '#alternative_workline_reference_name' do
    context 'when the plate purpose for my plate has alternative workline identifier' do
      let(:plate) { create :v2_plate, purpose_name: 'Plate with more holes' }

      it 'returns the configured reference purpose' do
        ref = SearchHelper.alternative_workline_reference_name(plate)
        expect(ref).to eq('Plate with holes')
      end
    end

    context 'when the plate purpose for my plate does not have alternative' do
      let(:plate) { create :v2_plate, purpose_name: 'Plate with less holes' }
      it 'returns nil' do
        ref = SearchHelper.alternative_workline_reference_name(plate)
        expect(ref).to eq(nil)
      end
    end
  end
end

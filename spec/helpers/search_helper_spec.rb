# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  context '#alternative_workline_reference_names' do
    let(:yaml) do
      %(
          LB Lib PCR-XP:
            :name: "LB Lib PCR-XP"
            :asset_type: "plate"
            :alternative_workline_identifier: true
          LB Lib Pool:
            :name: "LB Lib Pool"
            :asset_type: "tube"
      )
    end
    let(:data) do
      YAML.safe_load(yaml, [Symbol]).each_with_object({}) do |list, memo|
        k, v = list
        memo[k] = OpenStruct.new(v)
      end
    end
    before do
      allow(Settings).to receive(:purposes).and_return(data)
    end
    it 'retuns the list of alternative workline reference names (purposes names that act as a reference)' do
      expect(SearchHelper.alternative_workline_reference_names).to eq(['LB Lib PCR-XP'])
    end
  end
end

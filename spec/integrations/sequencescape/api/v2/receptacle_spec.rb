# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sequencescape::Api::V2::Receptacle do
  let(:wrong_units_molarity) do
    create(:qc_result, key: 'molarity', value: '0.0425', units: 'mM', created_at: Time.utc(2020, 1, 2, 3, 4, 5))
  end
  let(:early_molarity) do
    create(:qc_result, key: 'molarity', value: '8.6', units: 'nM', created_at: Time.utc(2020, 2, 3, 4, 5, 6))
  end
  let(:later_molarity) do
    create(:qc_result, key: 'molarity', value: '6.5', units: 'nM', created_at: Time.utc(2020, 3, 4, 5, 6, 7))
  end
  let(:volume) do
    create(
      :qc_result,
      key: 'volume',
      value: '250',
      units: 'ul',
      created_at: Time.utc(2020, 11, 12, 13, 14, 15) # Latest of all the creation times
    )
  end
  let(:receptacle) do
    create(:v2_receptacle, qc_results: [wrong_units_molarity, early_molarity, later_molarity, volume])
  end

  describe '#all_latest_qc' do
    it 'gives all the latest results back for each key' do
      expect(receptacle.all_latest_qc).to contain_exactly(later_molarity, volume)
    end

    context 'when no qc results' do
      let(:receptacle) { create(:v2_receptacle, qc_results: []) }

      it 'gives no results back' do
        expect(receptacle.all_latest_qc).to eq []
      end
    end

    context 'when qc results are not defined' do
      let(:receptacle) do
        create(:v2_receptacle)
      end

      before do
        receptacle.qc_results = nil # if nil is provided to the factory it will be replace with an empty array
      end

      it 'gives no results back' do
        expect(receptacle.all_latest_qc).to eq []
      end
    end
  end

  describe '#latest_molarity' do
    it 'gives the latest molarity back' do
      expect(receptacle.latest_molarity).to be later_molarity
    end

    context 'when no qc results' do
      let(:receptacle) { create(:v2_receptacle, qc_results: []) }

      it 'gives back nil' do
        expect(receptacle.latest_molarity).to be_nil
      end
    end

    context 'when no molarity in qc results' do
      let(:receptacle) { create(:v2_receptacle, qc_results: [volume]) }

      it 'gives back nil' do
        expect(receptacle.latest_molarity).to be_nil
      end
    end

    context 'when reduced set of molarity results' do
      let(:receptacle) { create(:v2_receptacle, qc_results: [wrong_units_molarity, early_molarity]) }

      it 'gives back the latest of those present' do
        expect(receptacle.latest_molarity).to be early_molarity
      end
    end
  end

  describe '#latest_qc' do
    context 'when lookup is present' do
      it 'gives the latest molarity with nM back' do
        expect(receptacle.latest_qc(key: 'molarity', units: 'nM')).to be later_molarity
      end

      it 'gives the latest molarity with mM back' do
        expect(receptacle.latest_qc(key: 'molarity', units: 'mM')).to be wrong_units_molarity
      end

      it 'gives the latest volume with ul back' do
        expect(receptacle.latest_qc(key: 'volume', units: 'ul')).to be volume
      end
    end

    context 'when lookup is absent' do
      it 'gives nil for molarity in M' do
        expect(receptacle.latest_qc(key: 'molarity', units: 'M')).to be_nil
      end

      it 'gives nil for other_result in mM' do
        expect(receptacle.latest_qc(key: 'other_result', units: 'mM')).to be_nil
      end

      it 'gives nil for volume in ml' do
        expect(receptacle.latest_qc(key: 'volume', units: 'ml')).to be_nil
      end

      it 'gives nil for other_result in ul' do
        expect(receptacle.latest_qc(key: 'other_result', units: 'ul')).to be_nil
      end
    end
  end
end

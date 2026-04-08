# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LabwareCreators::BalancedPooledTube::BalancingCalculator do
  subject(:calculator) do
    described_class.new(samples, barcodes, pf_barcode_reads, mean_cvg, batch_id)
  end

  let(:samples) { %w[S1 S2] }
  let(:barcodes) { %w[Z0001 Z0002] }
  let(:pf_barcode_reads) { [79_229_127, 70_266_606] }
  let(:mean_cvg) { [6.69, 5.95] }
  let(:batch_id) { '12345' }

  describe '#initialize' do
    it { expect(calculator.samples).to eq(samples) }
    it { expect(calculator.barcodes).to eq(barcodes) }
    it { expect(calculator.pf_barcode_reads).to eq(pf_barcode_reads) }
    it { expect(calculator.mean_cvg).to eq(mean_cvg) }
    it { expect(calculator.batch_id).to eq(batch_id) }
  end

  describe '#average_cov_waf1' do
    it { expect(calculator.average_cov_waf1).to eq(6.32) }
  end

  describe '#cov_need_waf2_and_waf3' do
    it { expect(calculator.cov_need_waf2_and_waf3(0)).to eq(12.27) }
    it { expect(calculator.cov_need_waf2_and_waf3(1)).to eq(13.01) }
  end

  describe '#exp_cov_waf2_waf3' do
    it { expect(calculator.exp_cov_waf2_waf3(0)).to eq(6.135) }
    it { expect(calculator.exp_cov_waf2_waf3(1)).to eq(6.505) }
  end

  describe '#pool_cf_waf2_waf3' do
    it { expect(calculator.pool_cf_waf2_waf3(0)).to eq(0.917) }
    it { expect(calculator.pool_cf_waf2_waf3(1)).to eq(1.0933) }
  end

  describe '#vol_to_pool' do
    it { expect(calculator.vol_to_pool(0)).to eq(9.17) }
    it { expect(calculator.vol_to_pool(1)).to eq(10.933) }
  end

  describe '#calculate' do
    let(:result) { calculator.calculate }

    it { expect(result.keys).to eq([0, 1]) }

    it {
      expect(result[0]).to include(
        sample: 'S1',
        barcode: 'Z0001',
        pf_barcode_reads: 79_229_127,
        mean_cvg: 6.69,
        batch_id: '12345',
        'CovNeed Waf2&3': 12.27,
        'PoolCF Waf2&3': 0.917,
        'ExpCov Waf2': 6.135,
        'Average Cov Waf1': 6.32,
        'Vol to pool': 9.17
      )
    }

    it {
      expect(result[1]).to include(
        sample: 'S2',
        barcode: 'Z0002',
        pf_barcode_reads: 70_266_606,
        mean_cvg: 5.95,
        batch_id: '12345',
        'CovNeed Waf2&3': 13.01,
        'PoolCF Waf2&3': 1.0933,
        'ExpCov Waf2': 6.505,
        'Average Cov Waf1': 6.32,
        'Vol to pool': 10.933
      )
    }
  end
end

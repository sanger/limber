# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/ultima_balancing.csv.erb' do
  let(:aliquot1_pm1) { build :poly_metadatum, key: 'sample', value: 's1' }
  let(:aliquot1_pm2) { build :poly_metadatum, key: 'barcode', value: 'Z0001' }
  let(:aliquot1_pm3) { build :poly_metadatum, key: 'pf_barcode_reads', value: '84' }
  let(:aliquot1_pm4) { build :poly_metadatum, key: 'mean_cvg', value: '7.29' }
  let(:aliquot1_pm5) { build :poly_metadatum, key: 'CovNeed Waf2&3', value: '20.7' }
  let(:aliquot1_pm6) { build :poly_metadatum, key: 'PoolCF Waf2&3', value: '1.42' }
  let(:aliquot1_pm7) { build :poly_metadatum, key: 'ExpCov Waf2', value: '10.4' }
  let(:aliquot1_pm8) { build :poly_metadatum, key: 'Average Cov Waf1', value: '9.25' }
  let(:aliquot1_pm9) { build :poly_metadatum, key: 'Vol to pool', value: '14.2' }

  let(:aliquot2_pm1) { build :poly_metadatum, key: 'sample', value: 's2' }
  let(:aliquot2_pm2) { build :poly_metadatum, key: 'barcode', value: 'Z0002' }
  let(:aliquot2_pm3) { build :poly_metadatum, key: 'pf_barcode_reads', value: '86' }
  let(:aliquot2_pm4) { build :poly_metadatum, key: 'mean_cvg', value: '8.29' }
  let(:aliquot2_pm5) { build :poly_metadatum, key: 'CovNeed Waf2&3', value: '21.7' }
  let(:aliquot2_pm6) { build :poly_metadatum, key: 'PoolCF Waf2&3', value: '2.42' }
  let(:aliquot2_pm7) { build :poly_metadatum, key: 'ExpCov Waf2', value: '11.4' }
  let(:aliquot2_pm8) { build :poly_metadatum, key: 'Average Cov Waf1', value: '10.25' }
  let(:aliquot2_pm9) { build :poly_metadatum, key: 'Vol to pool', value: '15.2' }

  let(:tube) do
    t = create(
      :tube,
      aliquot_count: 2
    )
    t.aliquots[0].poly_metadata = [aliquot1_pm1, aliquot1_pm2, aliquot1_pm3, aliquot1_pm4, aliquot1_pm5,
                                   aliquot1_pm6, aliquot1_pm7, aliquot1_pm8, aliquot1_pm9]
    t.aliquots[1].poly_metadata = [aliquot2_pm1, aliquot2_pm2, aliquot2_pm3, aliquot2_pm4, aliquot2_pm5,
                                   aliquot2_pm6, aliquot2_pm7, aliquot2_pm8, aliquot2_pm9]
    t
  end

  before do
    assign(:tube, tube)
  end

  # NB. poly_metadata values are strings, so all values from poly_metadata will come out as strings in the csv
  let(:expected_content) do
    [
      ['sample', 'barcode', 'pf_barcode_reads', 'Mean_cvg', 'CovNeed Waf2&3', 'PoolCF Waf2&3', 'ExpCov Waf2',
       'ExpCov Waf3', 'AverageCov Waf1', 'Vol to pool'],
      [
        aliquot1_pm1.value,
        aliquot1_pm2.value,
        aliquot1_pm3.value,
        aliquot1_pm4.value,
        aliquot1_pm5.value,
        aliquot1_pm6.value,
        # pm7 twice because ExpCov Waf2 and Waf3 are the same
        aliquot1_pm7.value,
        aliquot1_pm7.value,
        aliquot1_pm8.value,
        aliquot1_pm9.value
      ],
      [
        aliquot2_pm1.value,
        aliquot2_pm2.value,
        aliquot2_pm3.value,
        aliquot2_pm4.value,
        aliquot2_pm5.value,
        aliquot2_pm6.value,
        # pm7 twice because ExpCov Waf2 and Waf3 are the same
        aliquot2_pm7.value,
        aliquot2_pm7.value,
        aliquot2_pm8.value,
        aliquot2_pm9.value
      ]
    ]
  end

  it 'renders the expected content' do
    expect(CSV.parse(render)).to eq(expected_content)
  end
end

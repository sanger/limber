# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'exports/bioscan_mbrave.tsv.erb' do
  has_a_working_api

  let(:labware) { create(:v2_tube) }

  before { assign(:tube, labware) }

  it 'renders the expected content' do
    parsed_csv = CSV.parse(render)
    expect(parsed_csv).to eq([['hi']])
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sequencescape::Api::V2::Well do
  let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }) }

  describe '#sanger_sample_id' do
    it 'returns the sanger_sample_id from the first aliquot on the well' do
      expect(well_a1.sanger_sample_id).to eq well_a1.aliquots.first.sample.first.sanger_sample_id
    end
  end

  describe '#supplier_name' do
    it 'returns the supplier_name from the first aliquot on the well' do
      expect(well_a1.supplier_name).to eq well_a1.aliquots.first.sample.first.sample_metadata.supplier_name
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Export do
  describe '::find' do
    subject { described_class.find(id) }

    context 'when the id exists' do
      let(:id) { 'concentrations_ngul' }
      it { is_expected.to be_a described_class }

      it { is_expected.to have_attributes(csv: 'concentrations_ngul', plate_includes: 'wells.qc_results') }
    end

    context 'when the id exists' do
      let(:id) { 'not_an_export' }
      it 'raise ActiveRecord::RecordNotFound' do
        expect { described_class.find(id) }.to raise_error(Export::NotFound)
      end
    end
  end
end

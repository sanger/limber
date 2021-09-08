# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelLcaPbmc, type: :model do
  context 'when creating the label of a plate' do
    let(:labware) { create :v2_plate }
    let(:label) { Labels::PlateLabelLcaPbmc.new(labware) }

    context '#qc_attributes' do
      it 'has the correct qc_attributes' do
        qc_attributes = label.qc_attributes

        expect(qc_attributes.size).to eq 4

        expect(qc_attributes[0][:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(qc_attributes[0][:bottom_left]).to eq "#{labware.barcode.human} QC4"
        expect(qc_attributes[0][:top_right]).to eq labware.stock_plate&.barcode&.human
        expect(qc_attributes[0][:barcode]).to eq "#{labware.barcode.human}-QC4"

        expect(qc_attributes[3][:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(qc_attributes[3][:bottom_left]).to eq "#{labware.barcode.human} QC1"
        expect(qc_attributes[3][:top_right]).to eq labware.stock_plate&.barcode&.human
        expect(qc_attributes[3][:barcode]).to eq "#{labware.barcode.human}-QC1"
      end
    end
  end
end

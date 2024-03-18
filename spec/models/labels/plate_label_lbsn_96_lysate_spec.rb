# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelLbsn96Lysate, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the labels for a plate' do
    let(:partner_id) { 'ABCD-1234' }

    let(:sample_metadata) { create :v2_sample_metadata, sample_description: partner_id }
    let(:sample) { create(:v2_sample, sample_metadata: sample_metadata) }
    let(:aliquot) { create :v2_aliquot, sample: sample }
    let(:well_c6) { create(:v2_well, position: { 'name' => 'C6' }, aliquots: [aliquot]) }
    let(:labware) { create :v2_plate, wells: [well_c6] }

    let(:label) { Labels::PlateLabelLbsn96Lysate.new(labware) }

    context '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:bottom_left]).to eq labware.barcode.human
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq [labware.role, labware.purpose.name].compact.join(' ')
        expect(attributes[:barcode]).to eq labware.barcode.machine
      end
    end

    context '#intermediate_attributes' do
      let(:truncated_partner_id) { partner_id.truncate(16, omission: '') }
      let(:expected_partner_id) { [truncated_partner_id, 'SDC'].compact.join('_') }

      context 'when the partner id is a normal length' do
        it 'has the correct intermediate attributes' do
          intermediate_attributes = label.intermediate_attributes[0]
          expect(intermediate_attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
          expect(intermediate_attributes[:bottom_left]).to eq labware.barcode.human
          expect(intermediate_attributes[:top_right]).to eq 'PARTNER ID LABEL'
          expect(intermediate_attributes[:bottom_right]).to eq expected_partner_id
          expect(intermediate_attributes[:barcode]).to eq expected_partner_id
        end
      end

      context 'when the partner id is long' do
        let(:partner_id) { 'ABCD-1234-THIS-IS-TOO-LONG-TO-FIT' }

        it 'truncates the partner id' do
          intermediate_attributes = label.intermediate_attributes[0]
          expect(intermediate_attributes[:bottom_right]).to eq expected_partner_id
          expect(intermediate_attributes[:barcode]).to eq expected_partner_id
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelLbsn96Lysate, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the labels for a plate' do
    # current partner ids have the format ABCD_123 i.e. 4 characters, an underscore, and 3 numbers
    let(:partner_id) { 'ABCD_123' }
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
      let(:expected_partner_id) { 'ABCD-123-SDC' }

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
        let(:partner_id) { 'ABCD_123_THIS_IS_TOO_LONG_TO_FIT' }
        let(:expected_partner_id) { 'ABCD-123-SDC' }

        it 'truncates the partner id to the max length allowed' do
          intermediate_attributes = label.intermediate_attributes[0]
          expect(intermediate_attributes[:bottom_right]).to eq expected_partner_id
          expect(intermediate_attributes[:barcode]).to eq expected_partner_id
        end
      end

      context 'when the first sample in the plate is a control' do
        let(:control_sample_name) { 'CONTROL_A1' }
        let(:control_sample_description) { 'control description' }

        let!(:control_sample_metadata) do
          create :v2_sample_metadata, supplier_name: control_sample_name, sample_description: control_sample_description
        end

        let(:control_sample) do
          create :v2_sample,
                 name: control_sample_name,
                 control: true,
                 control_type: 'positive',
                 sample_metadata: control_sample_metadata
        end

        let(:control_aliquot) { create :v2_aliquot, sample: control_sample }
        let(:well_a1) { create(:v2_well, position: { 'name' => 'A1' }, aliquots: [control_aliquot]) }
        let(:labware) { create :v2_plate, wells: [well_a1, well_c6] }

        it 'ignores the control sample in A1' do
          intermediate_attributes = label.intermediate_attributes[0]
          expect(intermediate_attributes[:bottom_right]).to eq expected_partner_id
          expect(intermediate_attributes[:barcode]).to eq expected_partner_id
        end
      end
    end

    context 'when there are no wells with aliquots in the labware' do
      let(:well_c6) { create(:v2_well, position: { 'name' => 'C6' }, aliquots: []) }

      it 'raises an error' do
        expect { label.intermediate_attributes }.to raise_error(
          StandardError,
          'No wells with aliquots found in this labware to fetch a sample'
        )
      end
    end
  end
end

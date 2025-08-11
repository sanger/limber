# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabel96Lysate, type: :model do
  it { expect(described_class).to be < Labels::Base }

  context 'when creating the labels for a plate' do
    # current partner ids have the format ABCD_123 i.e. 4 characters, an underscore, and 3 numbers
    let(:partner_id) { 'ABCD_123' }
    let(:sample_metadata) { create :sample_metadata, sample_description: partner_id }
    let(:sample) { create(:sample, sample_metadata:) }
    let(:aliquot) { create :aliquot, sample: }
    let(:well_c6) { create(:well, position: { 'name' => 'C6' }, aliquots: [aliquot]) }
    let(:labware) { create :plate, wells: [well_c6] }

    let(:label) { described_class.new(labware) }

    describe '#attributes' do
      it 'has the correct attributes' do
        attributes = label.attributes
        expect(attributes[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
        expect(attributes[:bottom_left]).to eq labware.barcode.human
        expect(attributes[:top_right]).to eq labware.workline_identifier
        expect(attributes[:bottom_right]).to eq [labware.role, labware.purpose.name].compact.join(' ')
        expect(attributes[:barcode]).to eq labware.barcode.machine
      end
    end

    describe '#additional_label_definitions' do
      let(:expected_partner_id) { 'ABCD-123-SDC' }

      context 'when the partner id is a normal length' do
        it 'has the correct intermediate attributes' do
          additional_label_definitions = label.additional_label_definitions[0]
          expect(additional_label_definitions[:top_left]).to eq Time.zone.today.strftime('%e-%^b-%Y')
          expect(additional_label_definitions[:bottom_left]).to eq labware.barcode.human
          expect(additional_label_definitions[:top_right]).to eq 'PARTNER ID LABEL'
          expect(additional_label_definitions[:bottom_right]).to eq expected_partner_id
          expect(additional_label_definitions[:barcode]).to eq expected_partner_id
        end
      end

      context 'when the partner id is long' do
        let(:partner_id) { 'ABCD_123_THIS_IS_TOO_LONG_TO_FIT' }
        let(:expected_partner_id) { 'ABCD-123-SDC' }

        it 'truncates the partner id to the max length allowed' do
          additional_label_definitions = label.additional_label_definitions[0]
          expect(additional_label_definitions[:bottom_right]).to eq expected_partner_id
          expect(additional_label_definitions[:barcode]).to eq expected_partner_id
        end
      end

      context 'when the partner id is empty' do
        let(:sample_metadata) { create :sample_metadata, sample_description: nil }

        let(:expected_message) { 'NO PARTNER ID FOUND' }

        it 'creates a label without the partner id shown' do
          additional_label_definitions = label.additional_label_definitions[0]
          expect(additional_label_definitions[:bottom_right]).to eq expected_message
          expect(additional_label_definitions[:barcode]).to be_nil
        end
      end

      context 'when the first sample in the plate is a control' do
        let(:control_sample_name) { 'CONTROL_A1' }
        let(:control_sample_description) { 'control description' }

        let!(:control_sample_metadata) do
          create :sample_metadata, supplier_name: control_sample_name, sample_description: control_sample_description
        end

        let(:control_sample) do
          create :sample,
                 name: control_sample_name,
                 control: true,
                 control_type: 'positive',
                 sample_metadata: control_sample_metadata
        end

        let(:control_aliquot) { create :aliquot, sample: control_sample }
        let(:well_a1) { create(:well, position: { 'name' => 'A1' }, aliquots: [control_aliquot]) }
        let(:labware) { create :plate, wells: [well_a1, well_c6] }

        it 'ignores the control sample in A1' do
          additional_label_definitions = label.additional_label_definitions[0]
          expect(additional_label_definitions[:bottom_right]).to eq expected_partner_id
          expect(additional_label_definitions[:barcode]).to eq expected_partner_id
        end
      end
    end

    context 'when there are no wells with aliquots in the labware' do
      let(:well_c6) { create(:well, position: { 'name' => 'C6' }, aliquots: []) }

      it 'raises an error' do
        expect { label.additional_label_definitions }.to raise_error(
          StandardError,
          'No wells with aliquots found in this labware to fetch a sample'
        )
      end
    end
  end
end

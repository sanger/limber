# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::FinalTube do
  it_behaves_like 'it only allows creation from tubes'

  context 'on creation' do
    subject { described_class.new(form_attributes) }

    before { stub_v2_tube(parent_tube) }

    let(:child_purpose_uuid) { 'child-purpose-uuid' }
    let(:parent_uuid) { 'parent-uuid' }
    let(:user_uuid) { 'user-uuid' }
    let(:transfer_template_uuid) { 'tube-to-tube-by-sub' } # Defined in spec_helper.rb
    let(:transfer) { create :v2_transfer }
    let(:transfers_attributes) do
      [
        {
          arguments: {
            user_uuid: user_uuid,
            source_uuid: parent_uuid,
            transfer_template_uuid: transfer_template_uuid
          },
          response: transfer
        }
      ]
    end

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid: parent_uuid, user_uuid: user_uuid } }

    context 'with a sibling-less parent tube' do
      let(:parent_tube) { create :v2_tube, uuid: parent_uuid }

      describe '#save' do
        it 'is valid' do
          expect_transfer_creation

          expect(subject.save).to be true
          expect(subject.redirection_target.to_param).to eq(transfer.destination_uuid)
        end
      end
    end

    context 'with a parent tube with siblings' do
      context 'when all are passed' do
        let(:parent_tube) { create(:v2_tube, uuid: parent_uuid, siblings_count: 1, state: 'passed', barcode_number: 1) }

        describe '#save' do
          it 'returns false' do
            expect(subject.save).to be false
          end
        end

        it 'is ready' do
          subject.each_sibling do |sibling|
            expect(sibling).to be_a(Sibling)
            expect(sibling.ready?).to be true
          end
        end

        describe '#save' do
          let(:form_attributes) do
            {
              purpose_uuid: child_purpose_uuid,
              parent_uuid: parent_uuid,
              parents: {
                '3980000001795' => '1',
                '1234567890123' => '1'
              },
              user_uuid: user_uuid
            }
          end

          let(:sibling_uuid) { 'sibling-tube-0' }
          let(:transfer_b) { create :v2_transfer }

          let(:transfers_attributes) do
            [
              {
                arguments: {
                  user_uuid: user_uuid,
                  source_uuid: parent_uuid,
                  transfer_template_uuid: transfer_template_uuid
                },
                response: transfer
              },
              {
                arguments: {
                  user_uuid: user_uuid,
                  source_uuid: sibling_uuid,
                  transfer_template_uuid: transfer_template_uuid
                },
                response: transfer_b
              }
            ]
          end

          it 'creates transfers per sibling' do
            expect_transfer_creation

            expect(subject).to be_valid
            expect(subject.save).to be true
          end
        end
      end
    end
  end
end

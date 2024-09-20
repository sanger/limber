# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/final_tube'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::FinalTube do
  has_a_working_api

  it_behaves_like 'it only allows creation from tubes'

  context 'on creation' do
    subject { LabwareCreators::FinalTube.new(api, form_attributes) }

    before { stub_api_get(parent_uuid, body: tube_json) }

    let(:controller) { TubeCreationController.new }
    let(:child_purpose_uuid) { 'child-purpose-uuid' }
    let(:parent_uuid) { 'parent-uuid' }
    let(:user_uuid) { 'user-uuid' }
    let(:multiplexed_library_tube_uuid) { 'multiplexed-library-tube--uuid' }
    let(:transfer_template_uuid) { 'tube-to-tube-by-sub' } # Defined in spec_helper.rb
    let(:transfer) { create :v2_transfer }

    let(:form_attributes) { { purpose_uuid: child_purpose_uuid, parent_uuid:, user_uuid: } }

    context 'with a sibling-less parent tube' do
      let(:tube_json) { json(:tube_without_siblings, uuid: parent_uuid) }

      describe '#save' do
        it 'should be vaild' do
          expect_api_v2_posts(
            'Transfer',
            [{ user_uuid:, source_uuid: parent_uuid, transfer_template_uuid: }],
            [transfer]
          )

          expect(subject.save).to be true
          expect(subject.redirection_target.to_param).to eq(transfer.destination_uuid)
        end
      end
    end

    context 'with a parent tube with siblings' do
      context 'when all are passed' do
        let(:tube_json) do
          json(:tube_with_siblings, uuid: parent_uuid, siblings_count: 1, state: 'passed', barcode_number: 1)
        end

        describe '#save' do
          it 'should return false' do
            expect(subject.save).to be false
          end
        end

        it 'should be ready' do
          subject.each_sibling do |sibling|
            expect(sibling).to be_a(Sibling)
            expect(sibling.ready?).to be true
          end
        end

        describe '#save' do
          let(:form_attributes) do
            {
              purpose_uuid: child_purpose_uuid,
              parent_uuid:,
              parents: {
                '3980000001795' => '1',
                '1234567890123' => '1'
              },
              user_uuid:
            }
          end

          let(:sibling_uuid) { 'sibling-tube-0' }
          let(:transfer_b) { create :v2_transfer }

          it 'should create transfers per sibling' do
            expect_api_v2_posts(
              'Transfer',
              [
                { user_uuid:, source_uuid: parent_uuid, transfer_template_uuid: },
                { user_uuid:, source_uuid: sibling_uuid, transfer_template_uuid: }
              ],
              [transfer, transfer_b]
            )

            expect(subject).to be_valid
            expect(subject.save).to be true
          end
        end
      end
    end
  end
end

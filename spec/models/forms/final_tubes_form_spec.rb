# frozen_string_literal: true
require 'spec_helper'
require 'forms/final_tubes_form'

# TaggingForm creates a plate and applies the given tag templates
describe Forms::FinalTubesForm do
  has_a_working_api

  subject do
    Forms::FinalTubesForm.new(form_attributes.merge(api: api))
  end

  before(:each) do
    Settings.transfer_templates['Transfer from tube to tube by submission'] = transfer_template_uuid
    stub_api_get(parent_uuid, body: tube_json)
    stub_api_get(transfer_template_uuid, body: json(:transfer_template, uuid: transfer_template_uuid))
  end

  let(:controller) { TubeCreationController.new }
  let(:child_purpose_uuid) { 'child-purpose-uuid' }
  let(:parent_uuid) { 'parent-uuid' }
  let(:user_uuid) { 'user-uuid' }
  let(:multiplexed_library_tube_uuid) { 'multiplexed-library-tube--uuid' }
  let(:transfer_template_uuid) { 'transfer-template-uuid' }

  let(:form_attributes) do
    {
      purpose_uuid: child_purpose_uuid,
      parent_uuid:  parent_uuid,
      user_uuid: user_uuid
    }
  end

  context 'with a sibling-less parent tube' do
    let(:transfer_request) do
      stub_api_post(transfer_template_uuid,
                    payload: { transfer: { user: user_uuid, source: parent_uuid } },
                    body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
    end

    let(:tube_json) { json(:tube_without_siblings, uuid: parent_uuid) }

    before(:each) do
      transfer_request
    end

    describe '#render' do
      it 'should immediately redirect' do
        expect(controller).to receive(:redirect_to_form_destination).with(subject).and_return(true)
        subject.render(controller)
        expect(subject.child).to eq(controller: :tubes, action: :show, id: 'multiplexed-library-tube--uuid')
        expect(transfer_request).to have_been_made.once
      end
    end
  end

  context 'with a parent tube with siblings' do
    context 'when all are passed' do
      let(:tube_json) { json(:tube_with_siblings, uuid: parent_uuid, siblings_count: 1, state: 'passed', barcode_number: 1) }

      describe '#render' do
        it 'should immediately render' do
          expect(controller).to receive(:render).with('multi_tube_pooling').and_return(true)
          subject.render(controller)
        end
      end

      it 'should be ready' do
        subject.each_sibling do |sibling|
          expect(sibling).to be_a(Sibling)
          expect(sibling.ready?).to be true
        end
      end

      describe '#save!' do
        let(:form_attributes) do
          {
            purpose_uuid: child_purpose_uuid,
            parent_uuid:  parent_uuid,
            parents:  {
              '3980000001795' => '1',
              '1234567890123' => '1'
            },
            user_uuid: user_uuid
          }
        end

        let(:sibling_uuid) { 'sibling-tube-0' }
        let(:transfer_request) do
          stub_api_post(transfer_template_uuid,
                        payload: { transfer: { user: user_uuid, source: parent_uuid } },
                        body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
        end
        let(:transfer_request_b) do
          stub_api_post(transfer_template_uuid,
                        payload: { transfer: { user: user_uuid, source: sibling_uuid } },
                        body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
        end

        before(:each) do
          transfer_request
          transfer_request_b
        end

        it 'should create transfers per sibling' do
          subject.save!
          expect(transfer_request).to have_been_made.once
          expect(transfer_request_b).to have_been_made.once
        end
      end
    end
  end
end

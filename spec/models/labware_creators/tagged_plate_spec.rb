# frozen_string_literal: true

require 'spec_helper'
require 'labware_creators/base'
require_relative '../../support/shared_tagging_examples'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TaggedPlate, tag_plate: true do
  it_behaves_like 'it only allows creation from plates'

  has_a_working_api

  let(:plate_uuid) { 'example-plate-uuid' }
  let(:plate_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:pools) { 0 }
  let(:plate) { json :plate, uuid: plate_uuid, barcode_number: '2', pool_sizes: [8, 8], submission_pools_count: pools }
  let(:wells) { json :well_collection, size: 16 }
  let(:wells_in_column_order) { WellHelpers.column_order }
  let(:transfer_template_uuid) { 'custom-pooling' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }

  let(:child_purpose_uuid) { 'child-purpose' }
  let(:child_purpose_name) { 'Child Purpose' }

  let(:user_uuid) { 'user-uuid' }

  let(:plate_request) { stub_api_get(plate_uuid, body: plate) }
  let(:wells_request) { stub_api_get(plate_uuid, 'wells', body: wells) }

  before do
    create :purpose_config, name: child_purpose_name, uuid: child_purpose_uuid
    plate_request
    wells_request
  end

  subject do
    LabwareCreators::TaggedPlate.new(api, form_attributes)
  end

  context 'on new' do
    let(:form_attributes) do
      {
        purpose_uuid: child_purpose_uuid,
        parent_uuid: plate_uuid
      }
    end

    # These values all describe the returned json.
    # They are used to prevent magic numbers from appearing in the specs
    let(:plate_size) { 96 }
    let(:occupied_wells) { 30 }
    let(:pool_size) { 15 }
    let(:largest_tag_group) { 120 }

    let(:maximum_tag_offset)  { largest_tag_group - occupied_wells }
    let(:maximum_well_offset) { plate_size - occupied_wells + 1 }

    it 'can be created' do
      expect(subject).to be_a LabwareCreators::TaggedPlate
    end

    it 'describes the parent barcode' do
      expect(subject.parent.barcode.ean13).to eq(plate_barcode)
    end

    it 'describes the parent uuid' do
      expect(subject.parent_uuid).to eq(plate_uuid)
    end

    it 'describes the purpose uuid' do
      expect(subject.purpose_uuid).to eq(child_purpose_uuid)
    end

    context 'fetching layout templates' do
      before do
        stub_api_get('tag_layout_templates', body: json(:tag_layout_template_collection, size: 2))
      end

      let(:layout_hash) do
        WellHelpers.column_order.each_with_index.map do |w, i|
          pool = i < 8 ? 1 : 2
          [w, [pool, i + 1]]
        end
      end
      # Recording existing behaviour here before refactoring, but this looks like it might be just for pool tagging. Which is noe unused.
      it 'lists tag groups' do
        expect(subject.tag_plates_list).to eq('tag-layout-template-0' => { tags: layout_hash, used: false, dual_index: false, approved: true },
                                              'tag-layout-template-1' => { tags: layout_hash, used: false,
                                                                           dual_index: false, approved: true })
      end
    end

    context 'when a submission is split over multiple plates' do
      let(:pools) { 1 }
      before do
        stub_api_get(plate_uuid, 'submission_pools', body: pool_json)
      end
      context 'and tubes have been used' do
        let(:pool_json) do
          json(:dual_submission_pool_collection,
               used_tag2_templates: [{ uuid: 'tag2-layout-template-0', name: 'Used template' }])
        end
        it 'requires tag2' do
          expect(subject.requires_tag2?).to be true
        end

        context 'with advertised tag2 templates' do
          before do
            stub_api_get('tag2_layout_templates', body: json(:tag2_layout_template_collection))
          end

          it 'describes only the unused tube' do
            expect(subject.tag_tubes_list).to eq('tag2-layout-template-0' => { dual_index: true, used: true, approved: true },
                                                 'tag2-layout-template-1' => { dual_index: true, used: false,
                                                                               approved: true })
            expect(subject.tag_tubes_names).to eq(['Tag2 layout 1'])
          end

          it 'enforces use of tubes' do
            expect(subject.acceptable_tag2_sources).to eq ['tube']
          end
        end
      end
      context 'and nothing has been used' do
        let(:pool_json) do
          json(:dual_submission_pool_collection)
        end
        it 'allows tubes or plates' do
          expect(subject.acceptable_tag2_sources).to eq %w[tube plate]
        end
      end
      context 'and dual index plates have been used' do
        let(:pool_json) do
          json(:dual_submission_pool_collection,
               used_tag_templates: [{ uuid: 'tag-layout-template-0', name: 'Used template' }])
        end
        it 'enforces use of plates' do
          expect(subject.acceptable_tag2_sources).to eq ['plate']
        end
      end
    end

    context 'when a submission is not split over multiple plates' do
      before do
        stub_api_get(plate_uuid, 'submission_pools', body: json(:submission_pool_collection))
      end

      it 'does not require tag2' do
        expect(subject.requires_tag2?).to be false
      end

      it 'allows tubes or plates' do
        expect(subject.acceptable_tag2_sources).to eq %w[tube plate]
      end
    end

    context 'when a submission is not split over multiple plates but a plate has been recorded' do
      before do
        stub_api_get(plate_uuid, 'submission_pools',
                     body: json(:submission_pool_collection,
                                used_tag_templates: [{ uuid: 'tag-layout-template-0', name: 'Used template' }]))
      end

      it 'does not require tag2' do
        expect(subject.requires_tag2?).to be false
      end

      it 'allows tubes or plates' do
        expect(subject.acceptable_tag2_sources).to eq %w[tube plate]
      end
    end
  end

  context 'On create' do
    let(:tag_plate_barcode) { '1234567890' }
    let(:tag_plate_uuid) { 'tag-plate' }
    let(:tag_template_uuid) { 'tag-layout-template' }
    let(:tag2_tube_barcode) { '2345678901' }
    let(:tag2_tube_uuid) { 'tag2-tube' }
    let(:tag2_template_uuid) { 'tag2-layout-template' }

    include_context 'a tag plate creator'

    before do
      stub_api_get(plate_uuid, 'submission_pools', body: json(:submission_pool_collection))
    end

    context 'With no tag 2' do
      let(:form_attributes) do
        {
          purpose_uuid: child_purpose_uuid,
          parent_uuid: plate_uuid,
          user_uuid: user_uuid,
          tag_plate_barcode: tag_plate_barcode,
          tag_plate: { asset_uuid: tag_plate_uuid, template_uuid: tag_template_uuid }
        }
      end

      it 'can be created' do
        expect(subject).to be_a LabwareCreators::TaggedPlate
      end

      it_behaves_like 'it has a custom page', 'tagged_plate'

      context 'on save' do
        Settings.transfer_templates['Custom pooling'] = 'custom-plate-transfer-template-uuid'

        it 'creates a tag plate' do
          expect(subject.save).to be true
          expect(state_change_tag_plate_request).to have_been_made.once
          expect(plate_conversion_request).to have_been_made.once
          expect(transfer_creation_request).to have_been_made.once
          expect(tag_layout_creation_request).to have_been_made.once
        end

        it 'has the correct child (and uuid)' do
          expect(subject.save).to be true
          expect(subject.child.uuid).to eq(tag_plate_uuid)
        end
      end
    end

    context 'With tag 2' do
      let(:form_attributes) do
        {
          purpose_uuid: child_purpose_uuid,
          parent_uuid: plate_uuid,
          user_uuid: user_uuid,
          tag_plate_barcode: tag_plate_barcode,
          tag_plate: { asset_uuid: tag_plate_uuid, template_uuid: tag_template_uuid },
          tag2_tube_barcode: tag2_tube_barcode,
          tag2_tube: { asset_uuid: tag2_tube_uuid, template_uuid: tag2_template_uuid }
        }
      end

      it 'can be created' do
        expect(subject).to be_a LabwareCreators::TaggedPlate
      end

      it_behaves_like 'it has a custom page', 'tagged_plate'

      context 'on save!' do
        include_context 'a tag plate creator with dual indexing'

        it 'creates a tag plate' do
          subject.save!
          expect(state_change_tag_plate_request).to have_been_made.once
          expect(plate_conversion_request).to have_been_made.once
          expect(transfer_creation_request).to have_been_made.once
          expect(tag_layout_creation_request).to have_been_made.once
        end

        it 'applies tag2 specific actions' do
          subject.save!
          expect(state_change_tag2_request).to have_been_made.once
          expect(tag2_layout_request).to have_been_made.once
        end

        it 'has the correct child (and uuid)' do
          subject.save!
          expect(subject.child.uuid).to eq(tag_plate_uuid)
        end
      end
    end
  end
end

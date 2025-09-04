# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Charge and pass libraries', :js do
  has_a_working_api

  let(:user) { create :user, uuid: user_uuid }
  let(:user_uuid) { SecureRandom.uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:labware_uuid) { SecureRandom.uuid }
  let(:work_completions_attributes) do
    [{ target_uuid: labware_uuid, user_uuid: user_uuid, submission_uuids: submission_uuids }]
  end
  let(:template_uuid) { SecureRandom.uuid }

  # Setup stubs
  background do
    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  context 'plate with no submissions to be made' do
    before do
      create :purpose_config, uuid: 'example-purpose-uuid'
      stub_v2_plate(plate)
      stub_v2_plate(
        plate,
        stub_search: false,
        custom_includes: 'wells.aliquots.request.poly_metadata'
      )
      stub_v2_plate(plate, custom_query: [:plate_for_completion, plate.uuid])
    end

    let(:plate_barcode) { plate.labware_barcode.machine }
    let(:submission_uuids) { %w[pool-1-uuid pool-2-uuid] }
    let(:plate) do
      create :v2_plate,
             uuid: labware_uuid,
             state: 'passed',
             pool_sizes: [8, 8],
             include_submissions: true,
             well_factory: :v2_tagged_well
    end

    scenario 'charge and pass libraries' do
      expect_work_completion_creation

      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
    end
  end

  context 'tube with submissions to be made' do
    before do
      create :passable_tube, submission: { request_options:, template_uuid: }, uuid: 'example-purpose-uuid'
      stub_v2_tube(tube)
      stub_v2_tube(tube, custom_query: [:tube_for_completion, tube.uuid])
    end

    let(:submission_uuids) { [] }
    let(:request_options) { { read_length: '150' } }
    let(:tube) { create :v2_tube, uuid: labware_uuid, state: 'passed', purpose_uuid: 'example-purpose-uuid' }
    let(:tube_barcode) { tube.labware_barcode.machine }

    let(:orders_attributes) do
      [
        {
          attributes: {
            submission_template_uuid: template_uuid,
            submission_template_attributes: {
              asset_uuids: [labware_uuid],
              request_options: request_options,
              user_uuid: user_uuid
            }
          },
          uuid_out: 'order-uuid'
        }
      ]
    end

    let(:submissions_attributes) do
      [{ attributes: { and_submit: true, order_uuids: ['order-uuid'], user_uuid: user_uuid }, uuid_out: 'sub-uuid' }]
    end

    scenario 'charge and pass libraries with submissions' do
      expect_order_creation
      expect_submission_creation
      expect_work_completion_creation

      fill_in_swipecard_and_barcode user_swipecard, tube_barcode
      expect(find_by_id('tube-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
      expect(page).to have_content('Your submissions have been made and should be built shortly.')
    end
  end
end

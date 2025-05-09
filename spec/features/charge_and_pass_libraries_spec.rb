# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Charge and pass libraries', :js do
  has_a_working_api

  let(:user) { create :user, uuid: user_uuid }
  let(:user_uuid) { SecureRandom.uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:labware_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:labware_uuid) { SecureRandom.uuid }
  let(:work_completion_request) do
    { 'work_completion' => { target: labware_uuid, submissions: submissions, user: user_uuid } }
  end
  let(:work_completion) { json :work_completion }
  let(:template_uuid) { SecureRandom.uuid }

  # Setup stubs
  background do
    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
    stub_api_post('work_completions', payload: work_completion_request, body: work_completion)
  end

  context 'plate with no submissions to be made' do
    before do
      create :purpose_config, uuid: 'example-purpose-uuid'
      stub_v2_plate(plate)
      stub_v2_plate(plate, custom_query: [:plate_for_completion, plate.uuid])
    end

    let(:plate_barcode) { plate.labware_barcode.machine }
    let(:submissions) { %w[pool-1-uuid pool-2-uuid] }
    let(:plate) do
      create :v2_plate,
             uuid: labware_uuid,
             state: 'passed',
             pool_sizes: [8, 8],
             include_submissions: true,
             well_factory: :v2_tagged_well
    end

    scenario 'charge and pass libraries' do
      fill_in_swipecard_and_barcode user_swipecard, plate_barcode
      expect(find_by_id('plate-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
    end
  end

  context 'tube with submissions to be made' do
    let(:submissions) { [] }
    let(:request_options) { { read_length: '150' } }
    let(:tube) { create :v2_tube, uuid: labware_uuid, state: 'passed', purpose_uuid: 'example-purpose-uuid' }
    let(:tube_barcode) { tube.labware_barcode.machine }

    before do
      create :passable_tube, submission: { request_options:, template_uuid: }, uuid: 'example-purpose-uuid'
      stub_v2_tube(tube)
      stub_v2_tube(tube, custom_query: [:tube_for_completion, tube.uuid])

      # Stub the API for order creation
      stub_api_get(template_uuid, body: json(:submission_template, uuid: template_uuid))
      stub_api_post(
        template_uuid,
        'orders',
        payload: {
          order: {
            assets: [labware_uuid],
            request_options: request_options,
            user: user_uuid
          }
        },
        body: '{"order":{"uuid":"order-uuid"}}'
      )

      # Stub the API for submission creation
      stub_api_post(
        'submissions',
        payload: {
          submission: {
            orders: ['order-uuid'],
            user: user_uuid
          }
        },
        body: json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }])
      )

      # Stub the API for submission submission
      stub_api_post('sub-uuid', 'submit')
    end

    scenario 'charge and pass libraries with submissions' do
      fill_in_swipecard_and_barcode user_swipecard, tube_barcode
      expect(find_by_id('tube-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
      expect(page).to have_content('Your submissions have been made and should be built shortly.')
    end
  end
end

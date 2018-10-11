# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Charge and pass libraries', js: true do
  has_a_working_api

  let(:user)           { json :user, uuid: user_uuid }
  let(:user_uuid)      { SecureRandom.uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:labware_barcode)  { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:labware_uuid)     { SecureRandom.uuid }
  let(:default_tube_printer) { 'tube printer 1' }
  let(:work_completion_request) do
    { 'work_completion' => { target: labware_uuid, submissions: submissions, user: user_uuid } }
  end
  let(:work_completion) { json :work_completion }
  let(:template_uuid) { SecureRandom.uuid }

  # Setup stubs
  background do
    # Set-up the plate config
    Settings.purposes['example-purpose-uuid'] = purpose_spec

    # We look up the user
    stub_swipecard_search(user_swipecard, user)
    # We lookup the plate
    stub_asset_search(labware_barcode, example_labware)
    # We get the actual plate
    stub_api_get(labware_uuid, body: example_labware)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_post('work_completions', payload: work_completion_request, body: work_completion)
  end

  context 'plate with no submissions to be made' do
    let(:submissions) { ['pool-1-uuid', 'pool-2-uuid'] }
    let(:purpose_spec) { build :passable_plate }
    let(:example_labware) { json :plate, uuid: labware_uuid, state: 'passed', pool_sizes: [8, 8] }
    let(:example_plate_v2) { create :v2_plate, uuid: labware_uuid, state: 'passed', pool_sizes: [8, 8], include_submissions: true, well_factory: :v2_tagged_well }

    before do
      stub_v2_plate(example_plate_v2)
      stub_v2_plate(example_plate_v2, custom_includes: 'wells.aliquots.request.submission')
    end

    scenario 'charge and pass libraries' do
      fill_in_swipecard_and_barcode user_swipecard, labware_barcode
      expect(find('#plate-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
    end
  end

  context 'tube with submissions to be made' do
    let(:submissions) { [] }
    let(:request_options) { { read_length: '150' } }
    let(:purpose_spec) do
      build :passable_tube,
            submission: { request_options: request_options, template_uuid: template_uuid }
    end
    let(:example_labware) { json :tube, uuid: labware_uuid, state: 'passed', purpose_uuid: 'example-purpose-uuid' }

    let!(:order_request) do
      stub_api_get(template_uuid, body: json(:submission_template, uuid: template_uuid))
      stub_api_post(template_uuid, 'orders',
                    payload: { order: {
                      assets: [labware_uuid],
                      request_options: request_options,
                      user: user_uuid
                    } },
                    body: '{"order":{"uuid":"order-uuid"}}')
    end

    let!(:submission_request) do
      stub_api_post('submissions',
                    payload: { submission: { orders: ['order-uuid'], user: user_uuid } },
                    body:  json(:submission, uuid: 'sub-uuid', orders: [{ uuid: 'order-uuid' }]))
    end

    let!(:submission_submit) do
      stub_api_post('sub-uuid', 'submit')
    end

    scenario 'charge and pass libraries with submissions' do
      fill_in_swipecard_and_barcode user_swipecard, labware_barcode
      expect(find('#tube-show-page')).to have_content('Passed')
      click_button('Charge and pass libraries')
      expect(page).to have_content('Requests have been passed')
      expect(page).to have_content('Your submissions have been made and should be built shortly.')
    end
  end
end

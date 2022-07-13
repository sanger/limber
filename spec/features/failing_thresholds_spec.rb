# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Failing thresholds', js: true do
  has_a_working_api

  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:plate_barcode) { example_plate.barcode.machine }
  let(:plate_uuid) { SecureRandom.uuid }
  let(:below_threshold_qc) { create(:qc_result, key: 'molarity', value: '10', units: 'nM') }
  let(:above_threshold_qc) { create(:qc_result, key: 'molarity', value: '20', units: 'nM') }
  let(:wells) do
    [
      create(:v2_well, location: 'A1', state: 'passed', qc_results: [below_threshold_qc]),
      create(:v2_well, location: 'B1', state: 'passed', qc_results: [above_threshold_qc]),
      create(:v2_well, location: 'A2', state: 'passed', qc_results: [above_threshold_qc]),
      create(:v2_well, location: 'B2', state: 'failed', qc_results: [below_threshold_qc]),
      create(:v2_well, location: 'A3', state: 'passed', qc_results: [below_threshold_qc])
    ]
  end
  let(:example_plate) do
    create :v2_plate, uuid: plate_uuid, purpose_uuid: 'stock-plate-purpose-uuid', state: 'passed', wells: wells
  end

  let!(:state_change_request) do
    stub_api_post(
      'state_changes',
      payload: {
        'state_change' => {
          user: user_uuid,
          target: plate_uuid,
          contents: %w[A1 A3],
          target_state: 'failed',
          reason: 'Individual Well Failure',
          customer_accepts_responsibility: nil
        }
      },
      body: '{}' # We don't care about the response
    )
  end

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config, uuid: 'stock-plate-purpose-uuid'
    create :purpose_config, uuid: 'child-purpose-0'

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the actual plate

    2.times do # For both the initial find, and the redirect post state change
      stub_v2_plate(example_plate)
    end

    stub_api_get(
      plate_uuid,
      'wells',
      body: json(:well_collection, default_state: 'passed', custom_state: { 'B2' => 'failed' })
    )
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
  end

  scenario 'failing wells' do
    fill_in_swipecard_and_barcode user_swipecard, plate_barcode

    click_on('Fail Wells')

    fill_in 'Molarity', with: 15

    click_on('Fail selected wells')
    expect(find('#flashes')).to have_content('Selected wells have been failed')
    expect(state_change_request).to have_been_made
  end
end

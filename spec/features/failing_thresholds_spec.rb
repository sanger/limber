# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Failing thresholds', :js do
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

  let(:state_changes_attributes) do
    [
      {
        contents: %w[A1 A3],
        customer_accepts_responsibility: nil,
        reason: 'Individual Well Failure',
        target_state: 'failed',
        target_uuid: plate_uuid,
        user_uuid: user_uuid
      }
    ]
  end

  # Setup stubs
  background do
    # Set-up the plate config
    create :purpose_config,
           uuid: 'stock-plate-purpose-uuid',
           qc_thresholds: {
             molarity: {
               name: 'molarity',
               default_threshold: 20,
               max: 50,
               min: 5,
               units: 'nM'
             }
           }
    create :purpose_config, uuid: 'child-purpose-0'

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # We get the actual plate

    2.times do # For both the initial find, and the redirect post state change
      stub_v2_plate(example_plate)
      stub_v2_plate(
        example_plate,
        stub_search: false,
        custom_includes: 'wells.aliquots.request.poly_metadata'
      )
    end

    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  scenario 'failing wells' do
    expect_state_change_creation

    fill_in_swipecard_and_barcode user_swipecard, plate_barcode
    click_on('Fail Wells')
    fill_in 'Molarity', with: 15
    click_on('Fail selected wells')

    expect(find_by_id('flashes')).to have_content('Selected wells have been failed')
  end
end

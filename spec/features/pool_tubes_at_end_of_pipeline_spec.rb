# frozen_string_literal: true

require 'rails_helper'

feature 'Pool tubes at end of pipeline', js: true do
  has_a_working_api
  let(:user_uuid)             { 'user-uuid' }
  let(:user)                  { json :user, uuid: user_uuid }
  let(:user_swipecard)        { 'abcdef' }
  let(:tube_barcode)          { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:sibling_barcode)       { '1234567890123' }
  let(:tube_uuid)             { SecureRandom.uuid }
  let(:sibling_uuid) { 'sibling-tube-0' }
  let(:child_purpose_uuid)    { 'child-purpose-0' }
  let(:example_tube)          { json(:tube_with_siblings, uuid: tube_uuid, siblings_count: 1, state: 'passed', barcode_number: 1) }
  let(:transfer_template_uuid) { 'transfer-template-uuid' }
  let(:transfer_template) { json :transfer_template, uuid: transfer_template_uuid }
  let(:multiplexed_library_tube_uuid) { 'multiplexed-library-tube-uuid' }

  let(:transfer_request) do
    stub_api_post(transfer_template_uuid,
                  payload: { transfer: { user: user_uuid, source: tube_uuid } },
                  body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
  end
  let(:transfer_request_b) do
    stub_api_post(transfer_template_uuid,
                  payload: { transfer: { user: user_uuid, source: sibling_uuid } },
                  body: json(:transfer_between_tubes_by_submission, destination: multiplexed_library_tube_uuid))
  end

  # Setup stubs
  background do
    Settings.transfer_templates['Transfer from tube to tube by submission'] = 'transfer-template-uuid'

    # Set-up the tube config
    Settings.purposes = {}
    Settings.purposes['example-purpose-uuid'] = {
      presenter_class: 'Presenters::SimpleTubePresenter',
      asset_type: 'Tube',
      name: 'Example Purpose'
    }
    Settings.purposes[child_purpose_uuid] = {
      presenter_class: 'Presenters::FinalTubePresenter',
      asset_type: 'Tube',
      name: 'Final Tube Purpose',
      form_class: 'Forms::FinalTubesForm',
      parents: ['Example Purpose']
    }
    # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => user_swipecard } }, user)
    # We lookup the tube
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => tube_barcode } }, example_tube)
    # We get the actual tube
    stub_api_get(tube_uuid, body: example_tube)
    stub_api_get('barcode_printers', body: json(:barcode_printer_collection))
    stub_api_get('transfer-template-uuid', body: json(:transfer_template, uuid: 'transfer-template-uuid'))
    stub_api_get(multiplexed_library_tube_uuid, body: json(:multiplexed_library_tube))
    transfer_request
    transfer_request_b
  end

  shared_examples 'a tube validation form' do
    scenario 'of a recognised type' do
      fill_in_swipecard_and_barcode user_swipecard, tube_barcode
      page_title = find('#tube-title')
      expect(page_title).to have_text('Example Purpose')
      click_on('Add an empty Final Tube Purpose tube')
      expect(page).to have_text('Multi Tube pooling')
      expect(page).to have_button('Make Tube', disabled: true)
      fill_in('Tube barcode', with: tube_barcode)
      find_field('Tube barcode').send_keys barcode_reader_key
      fill_in('Tube barcode', with: sibling_barcode)
      find_field('Tube barcode').send_keys barcode_reader_key
      click_on('Make Tube')
      expect(page).to have_content('New empty labware added to the system.')
      expect(transfer_request).to have_been_made.once
      expect(transfer_request_b).to have_been_made.once
    end
  end

  # Barcode readers can have different configurations.
  # To avoid frustrations when using different readers we
  # want to show the same behaviour.
  context 'when barcode readers send a tab' do
    let(:barcode_reader_key) { :tab }
    it_behaves_like 'a tube validation form'
  end

  context 'when barcode readers send an enter' do
    let(:barcode_reader_key) { :enter }
    it_behaves_like 'a tube validation form'
  end
end

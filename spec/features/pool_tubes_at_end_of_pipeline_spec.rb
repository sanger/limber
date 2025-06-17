# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Pool tubes at end of pipeline', :js do
  let(:user_uuid) { 'user-uuid' }
  let(:user) { create :user, uuid: user_uuid }
  let(:user_swipecard) { 'abcdef' }
  let(:tube_barcode) { SBCF::SangerBarcode.new(prefix: 'NT', number: 1).machine_barcode.to_s }
  let(:sibling_barcode) { '1234567890123' }
  let(:tube_uuid) { SecureRandom.uuid }
  let(:sibling_uuid) { 'sibling-tube-0' }
  let(:child_purpose_uuid) { 'child-purpose-0' }
  let(:tube) do
    create(
      :v2_tube,
      barcode_number: 1,
      purpose_name: 'Example Purpose',
      siblings_count: 1,
      state: 'passed',
      uuid: tube_uuid
    )
  end
  let(:multiplexed_library_tube_uuid) { 'multiplexed-library-tube-uuid' }
  let(:transfers_attributes) do
    [
      {
        arguments: {
          user_uuid: user_uuid,
          source_uuid: tube_uuid,
          transfer_template_uuid: 'tube-to-tube-by-sub'
        },
        response: create(:v2_transfer_between_tubes, destination_uuid: multiplexed_library_tube_uuid)
      },
      {
        arguments: {
          user_uuid: user_uuid,
          source_uuid: sibling_uuid,
          transfer_template_uuid: 'tube-to-tube-by-sub'
        },
        response: create(:v2_transfer_between_tubes, destination_uuid: multiplexed_library_tube_uuid)
      }
    ]
  end

  # Setup stubs
  background do
    # Set-up the tube config
    create :tube_config, name: 'Example Purpose', uuid: 'example-purpose-uuid'
    create :tube_config,
           presenter_class: 'Presenters::FinalTubePresenter',
           name: 'Final Tube Purpose',
           creator_class: 'LabwareCreators::FinalTube',
           uuid: child_purpose_uuid
    create :pipeline, relationships: { 'Example Purpose' => 'Final Tube Purpose' }

    # We look up the user
    stub_swipecard_search(user_swipecard, user)

    # Stub tubes
    stub_v2_tube(tube)
    stub_v2_tube(create(:v2_tube, uuid: multiplexed_library_tube_uuid))

    stub_v2_barcode_printers(create_list(:v2_plate_barcode_printer, 3))
  end

  shared_examples 'a tube validation form' do
    scenario 'of a recognised type' do
      expect_transfer_creation

      fill_in_swipecard_and_barcode user_swipecard, tube_barcode
      page_title = find_by_id('tube-title')
      expect(page_title).to have_text('Example Purpose')
      click_on('Add an empty Final Tube Purpose tube')
      expect(page).to have_text('Multi Tube pooling')
      expect(page).to have_button('Make Tube', disabled: true)
      scan_in('Tube barcode', with: tube_barcode)
      find_field('Tube barcode').send_keys barcode_reader_key
      scan_in('Tube barcode', with: sibling_barcode)
      find_field('Tube barcode').send_keys barcode_reader_key
      click_on('Make Tube')
      expect(page).to have_content('New empty labware added to the system.')
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

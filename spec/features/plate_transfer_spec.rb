# frozen_string_literal: true
require 'rails_helper'

feature 'Plate transfer', js: true do
  has_a_working_api

  let(:user_uuid) { SecureRandom.uuid }
  let(:user)              { json :user, uuid: user_uuid }
  let(:swipecard)         { 'abcdef' }
  let(:robot_barcode)     { 'robot_barcode' }
  let(:plate_barcode_1)   { SBCF::SangerBarcode.new(prefix: 'DN', number: 1).machine_barcode.to_s }
  let(:plate_barcode_2)   { SBCF::SangerBarcode.new(prefix: 'DN', number: 2).machine_barcode.to_s }
  let(:plate_uuid)        { SecureRandom.uuid }
  let(:example_plate)     { json :stock_plate, uuid: plate_uuid, purpose_name: 'LB End Prep', purpose_uuid: 'lb_end_prep_uuid' }
  let(:example_plate_without_metadata) { json :stock_plate, uuid: plate_uuid, purpose_name: 'LB End Prep', purpose_uuid: 'lb_end_prep_uuid', state: 'started' }
  let(:example_plate_with_metadata) { json :stock_plate_with_metadata, uuid: plate_uuid, purpose_name: 'LB End Prep', purpose_uuid: 'lb_end_prep_uuid', state: 'started' }
  let(:settings) { YAML.load_file(Rails.root.join('spec', 'data', 'settings.yml')).with_indifferent_access }

  # Setup stubs
  background do
    # Set-up the plate robot
    Settings.robots['bravo-lb-post-shear-to-lb-end-prep'] = settings[:robots]['bravo-lb-post-shear-to-lb-end-prep']
    Settings.robots['bravo-lb-end-prep'] = settings[:robots]['bravo-lb-end-prep']

    # # We look up the user
    stub_search_and_single_result('Find user by swipecard code', { 'search' => { 'swipecard_code' => swipecard } }, user)
  end

  scenario 'starts the robot and saves the robot barcode' do
    allow_any_instance_of(Robots::Robot).to receive(:verify).and_return(beds: { '580000004838' => true, '580000014851' => true }, valid: true, message: '')

    Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
    Settings.purposes['lb_end_prep_uuid'] = { state_changer_class: 'StateChangers::DefaultStateChanger' }
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode_2 } }, example_plate)
    stub_custom_metdatum_collections_post = stub_api_post('custom_metadatum_collections',
                                                          payload: { custom_metadatum_collection: { user: user_uuid, asset: plate_uuid, metadata: { created_with_robot: 'robot_barcode' } } },
                                                          body: json(:custom_metadatum_collection))
    stub_state_changes_post = stub_api_post(
      'state_changes',
      payload: {
        state_change: {
          target_state: 'started',
          reason: 'Robot bravo LB Post Shear => LB End Prep started',
          customer_accepts_responsibility: false, target: plate_uuid, user: user_uuid
        }
      },
      body: json(:state_change, target_state: 'started')
    )

    fill_in_swipecard_and_barcode(swipecard)

    # if we don't do this the next step doesn't work
    expect(page).to have_content('Jane Doe')
    click_button('Robots')
    click_link 'bravo LB Post Shear => LB End Prep'
    expect(page).to have_content('bravo LB Post Shear => LB End Prep')
    fill_in 'Scan robot', with: '123'
    within('#robot') do
      expect(page).to have_content('123')
    end
    fill_in 'Scan bed', with: '580000004838'
    fill_in 'Scan plate', with: plate_barcode_1
    within('#bed_list') do
      expect(page).not_to have_content("Robot: #{robot_barcode}")
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content('Bed: 580000004838')
    end
    fill_in 'Scan robot', with: robot_barcode
    within('#robot') do
      expect(page).not_to have_content('123')
      expect(page).to have_content(robot_barcode.to_s)
    end
    fill_in 'Scan bed', with: '580000014851'
    fill_in 'Scan plate', with: plate_barcode_2
    within('#bed_list') do
      expect(page).not_to have_content("Robot: #{robot_barcode}")
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content('Bed: 580000004838')
      expect(page).to have_content("Plate: #{plate_barcode_2}")
      expect(page).to have_content('Bed: 580000014851')
    end
    click_link('Validate Layout')
    within '#validation_report' do
      expect(page).to have_content('No problems detected!')
    end
    click_button('Start the bravo LB Post Shear => LB End Prep')
    expect(page).to have_content('Robot bravo LB Post Shear => LB End Prep has been started.')
    expect(stub_custom_metdatum_collections_post).to have_been_requested
    expect(stub_state_changes_post).to have_been_requested
  end

  scenario 'informs if the robot barcode is wrong' do
    Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode_1 } }, example_plate_without_metadata)

    fill_in_swipecard_and_barcode(swipecard)

    expect(page).to have_content('Jane Doe')
    click_button('Robots')
    click_link 'bravo LB End Prep'
    expect(page).to have_content('bravo LB End Prep')
    fill_in 'Scan robot', with: robot_barcode
    within('#robot') do
      expect(page).to have_content(robot_barcode.to_s)
    end
    fill_in 'Scan bed', with: '580000014851'
    fill_in 'Scan plate', with: plate_barcode_1
    within('#bed_list') do
      expect(page).not_to have_content("Robot: #{robot_barcode}")
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content('Bed: 580000014851')
    end
    click_link('Validate Layout')
    within '#validation_report' do
      expect(page).to have_content('There were problems: Your plate is not on the right robot')
    end
  end

  scenario 'verifies robot barcode' do
    Settings.purpose_uuids['LB End Prep'] = 'lb_end_prep_uuid'
    stub_search_and_single_result('Find assets by barcode', { 'search' => { 'barcode' => plate_barcode_1 } }, example_plate_with_metadata)
    stub_api_get('custom_metadatum_collection-uuid', body: json(:custom_metadatum_collection, metadata: { 'created_with_robot' => 'robot_barcode' }, uuid: 'custom_metadatum_collection-uuid'))

    fill_in_swipecard_and_barcode(swipecard)

    expect(page).to have_content('Jane Doe')
    click_button('Robots')
    click_link 'bravo LB End Prep'
    expect(page).to have_content('bravo LB End Prep')
    fill_in 'Scan robot', with: robot_barcode
    within('#robot') do
      expect(page).to have_content(robot_barcode.to_s)
    end
    fill_in 'Scan bed', with: '580000014851'
    fill_in 'Scan plate', with: plate_barcode_1
    within('#bed_list') do
      expect(page).not_to have_content("Robot: #{robot_barcode}")
      expect(page).to have_content("Plate: #{plate_barcode_1}")
      expect(page).to have_content('Bed: 580000014851')
    end

    click_link('Validate Layout')
    within '#validation_report' do
      expect(page).to have_content('No problems detected!')
    end
  end

  def fill_in_swipecard_and_barcode(swipecard)
    visit root_path

    within '.content-main' do
      fill_in 'User Swipecard', with: swipecard
      find_field('User Swipecard').send_keys :enter
    end
  end
end

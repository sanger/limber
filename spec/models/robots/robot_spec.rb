# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::Robot, :robots do
  include RobotHelpers

  let(:user_uuid) { SecureRandom.uuid }
  let(:source_plate_barcode) { source_plate.human_barcode }
  let(:source_purpose_name) { 'source_plate_purpose' }
  let(:source_purpose_uuid) { SecureRandom.uuid }
  let(:source_plate_state) { 'passed' }
  let(:target_plate_state) { 'pending' }
  let(:source_plate) do
    create :plate,
           barcode_number: 1,
           purpose_name: source_purpose_name,
           purpose_uuid: source_purpose_uuid,
           state: source_plate_state
  end
  let(:target_plate_barcode) { target_plate.human_barcode }
  let(:target_tube_barcode) { target_tube.human_barcode }
  let(:target_purpose_name) { 'target_plate_purpose' }
  let(:target_tube_purpose_name) { 'target_tube_purpose' }
  let(:target_plate) do
    create :plate,
           purpose_name: target_purpose_name,
           barcode_number: 2,
           parents: target_plate_parents,
           state: target_plate_state
  end
  let(:target_tube_state) { 'pending' }
  let(:target_tube) do
    create :tube,
           purpose_name: target_tube_purpose_name,
           barcode_number: 3,
           state: target_tube_state,
           parents: target_tube_parents
  end
  let(:target_plate_parents) { [source_plate] }
  let(:target_tube_parents) { [source_plate] }
  let(:custom_metadatum_collection) { create :custom_metadatum_collection, metadata: }
  let(:metadata) { { 'other_key' => 'value' } }

  let(:robot) { described_class.new(robot_spec.merge(user_uuid:)) }

  shared_examples 'a robot' do
    context 'with an unknown plate' do
      before { bed_labware_lookup_with_barcode('dodgy_barcode', []) }

      let(:scanned_layout) { { 'bed1_barcode' => ['dodgy_barcode'] } }

      it { is_expected.not_to be_valid }
    end

    context 'with a plate on an unknown bed' do
      let(:scanned_layout) { { 'bed99_barcode' => [source_plate_barcode] } }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#verify' do
    subject { robot.verify(bed_labwares: scanned_layout) }

    context 'a simple robot' do
      let(:source_purpose) { source_purpose_name }
      let(:target_purpose) { target_purpose_name }
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 2'
            },
            'bed2_barcode' => {
              'purpose' => target_purpose,
              'states' => ['pending'],
              'label' => 'Bed 1',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_plate)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_plate_barcode] } }

        context 'and related plates' do
          let(:target_plate_parents) { [source_plate] }

          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but source is of the wrong purpose' do
            let(:source_purpose) { 'Expected purpose' }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end

          context 'but target is of the wrong purpose' do
            let(:target_purpose) { 'Expected purpose' }
            let(:target_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and an unchecked additional parent' do
          let(:target_plate_parents) { [source_plate, create(:plate)] }

          it { is_expected.to be_valid }
        end

        context 'and no parents' do
          let(:target_plate_parents) { [] }

          it { is_expected.not_to be_valid }
        end

        context 'and a parent in the database of a different purpose and an empty parent bed' do
          let(:scanned_layout) { { 'bed1_barcode' => [], 'bed2_barcode' => [target_plate_barcode] } }

          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and multiple source purposes' do
          let(:source_purpose) { [source_purpose_name, 'Other'] }
          let(:target_plate_parents) { [source_plate] }

          it { is_expected.to be_valid }

          context 'but of the wrong purpose' do
            let(:source_purpose) { %w[Something Other] }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_plate_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }

          let(:target_plate_parents) { [source_plate] }

          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'a robot with pairs of beds to handle multiple parallel transfers' do
      let(:source_purpose) { source_purpose_name }
      let(:target_purpose) { target_purpose_name }
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => target_purpose,
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 3'
            },
            'bed4_barcode' => {
              'purpose' => target_purpose,
              'states' => ['pending'],
              'label' => 'Bed 4',
              'parent' => 'bed3_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      let(:source_plate2) do
        create :plate, barcode_number: 3, purpose_name: source_purpose_name, state: source_plate_state
      end
      let(:source_plate2_barcode) { source_plate2.human_barcode }
      let(:target_plate2_parents) { [source_plate2] }
      let(:target_plate2) do
        create :plate,
               purpose_name: target_purpose_name,
               barcode_number: 4,
               parents: target_plate2_parents,
               state: target_plate_state
      end
      let(:target_plate2_barcode) { target_plate2.human_barcode }

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_plate)
        bed_labware_lookup(source_plate2)
        bed_labware_lookup(target_plate2)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout two pairs but scanning a single pair of plates' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_plate_barcode] } }

        context 'and related plates' do
          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but source is of the wrong purpose' do
            let(:source_purpose) { 'Something' }
            let(:source_purpose_name) { 'Invalid plate purpose' }
            let(:source_purpose_uuid) { SecureRandom.uuid }

            it { is_expected.not_to be_valid }
          end

          context 'but target is of the wrong purpose' do
            let(:target_purpose) { 'Something' }
            let(:target_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and an unchecked additional parent' do
          let(:target_plate_parents) { [source_plate, create(:plate)] }

          it { is_expected.to be_valid }
        end

        context 'and no parents' do
          let(:target_plate_parents) { [] }

          it { is_expected.not_to be_valid }
        end

        context 'and the target plate of the pair is not scanned' do
          let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [] } }

          it { is_expected.not_to be_valid }
        end

        context 'and the source plate of the pair is not scanned' do
          let(:scanned_layout) { { 'bed1_barcode' => [], 'bed2_barcode' => [target_plate_barcode] } }

          it { is_expected.not_to be_valid }
        end

        context 'and a parent in the database of a different purpose and an empty parent bed' do
          let(:scanned_layout) { { 'bed1_barcode' => [], 'bed2_barcode' => [target_plate_barcode] } }

          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and robot config allows multiple source purposes' do
          let(:source_purpose) { [source_purpose_name, 'Other'] }

          it { is_expected.to be_valid }

          context 'but when the wrong source plate purpose' do
            let(:source_purpose) { %w[Something Other] }
            let(:source_purpose_name) { 'Invalid plate purpose' }
            let(:source_purpose_uuid) { SecureRandom.uuid }

            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'with a valid layout two pairs and scanning both pairs of plates' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed2_barcode' => [target_plate_barcode],
            'bed3_barcode' => [source_plate2_barcode],
            'bed4_barcode' => [target_plate2_barcode]
          }
        end

        context 'and related plates' do
          it { is_expected.to be_valid }

          context 'but with a source plate in one pair in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but with a source plate in one pair of the wrong purpose' do
            let(:source_purpose) { 'Something' }
            let(:source_purpose_name) { 'Invalid plate purpose' }
            let(:source_purpose_uuid) { SecureRandom.uuid }

            it { is_expected.not_to be_valid }
          end

          context 'but with a target plate in one pair of the wrong purpose' do
            let(:target_purpose) { 'Something' }
            let(:target_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'and if one target plate has an unrelated parent' do
          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and if one target plate has an unchecked additional parent' do
          let(:target_plate_parents) { [source_plate, create(:plate)] }

          it { is_expected.to be_valid }
        end

        context 'and if one target plate has no parents' do
          let(:target_plate_parents) { [] }

          it { is_expected.not_to be_valid }
        end

        context 'and the one target plate of one of the pairs is not scanned' do
          let(:scanned_layout) do
            {
              'bed1_barcode' => [source_plate_barcode],
              'bed2_barcode' => [],
              'bed3_barcode' => [source_plate2_barcode],
              'bed4_barcode' => [target_plate2_barcode]
            }
          end

          it { is_expected.not_to be_valid }
        end

        context 'and the one source plate of one of the pairs is not scanned' do
          let(:scanned_layout) do
            {
              'bed1_barcode' => [],
              'bed2_barcode' => [target_plate_barcode],
              'bed3_barcode' => [source_plate2_barcode],
              'bed4_barcode' => [target_plate2_barcode]
            }
          end

          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'a robot with beds with multiple parents' do
      let(:source_plate_2) do
        create :plate, barcode_number: 3, purpose_name: source_purpose_name, state: source_plate_state
      end
      let(:source_plate_2_barcode) { source_plate_2.human_barcode }
      let(:target_plate_parents) { [source_plate, source_plate_2] }
      let(:source_purpose) { source_purpose_name }

      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 2'
            },
            'bed3_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 3'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 1',
              'parents' => %w[bed1_barcode bed3_barcode],
              'target_state' => 'passed'
            },
            'bed4_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 4'
            },
            'bed6_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 6'
            },
            'bed5_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 5',
              'parents' => %w[bed4_barcode bed6_barcode],
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(source_plate_2)
        bed_labware_lookup(target_plate)
      end

      it_behaves_like 'a robot'

      context 'with only one parent scanned' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_plate_barcode] } }

        it { is_expected.not_to be_valid }
      end

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed3_barcode' => [source_plate_2_barcode],
            'bed2_barcode' => [target_plate_barcode]
          }
        end

        context 'and related plates' do
          let(:target_plate_parents) { [source_plate, source_plate_2] }

          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose) { 'Expected plate purpose' }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_plate_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_plate_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }

          let(:target_plate_parents) { [source_plate] }

          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'a robot with tubes as the target' do
      let(:source_purpose) { source_purpose_name }
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => 'target_tube_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_tube)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) { { 'bed1_barcode' => [source_plate_barcode], 'bed2_barcode' => [target_tube_barcode] } }

        context 'and related plates' do
          let(:target_tube_parents) { [source_plate] }

          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose) { 'Expected plate purpose' }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'but unrelated plates' do
          let(:target_tube_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'an multiple source purposes' do
          let(:source_purpose) { [source_purpose_name, 'Other'] }
          let(:target_tube_parents) { [source_plate] }

          it { is_expected.to be_valid }

          context 'but of the wrong purpose' do
            let(:source_purpose) { 'Expected plate purpose' }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end
      end

      context 'with multiple scans' do
        let(:scanned_layout) do
          { 'bed1_barcode' => [source_plate_barcode, 'Other barcode'], 'bed2_barcode' => [target_tube_barcode] }
        end

        context 'and related plates' do
          before { bed_labware_lookup_with_barcode([source_plate_barcode, 'Other barcode'], [source_plate]) }

          it { is_expected.not_to be_valid }
        end
      end
    end

    context 'a robot using a shared phiX parent tube' do
      let(:phix_tube_purpose_name) { 'phix_tube_purpose' }
      let(:phix_tube_state) { 'passed' }
      let(:phix_tube) do
        create :tube, purpose_name: phix_tube_purpose_name, barcode_number: 4, state: phix_tube_state
      end
      let(:phix_tube_barcode) { phix_tube.human_barcode }
      let(:source_purpose) { source_purpose_name }
      let(:target_purpose) { target_tube_purpose_name }

      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose,
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => target_purpose,
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parents' => %w[bed1_barcode bed3_barcode],
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => phix_tube_purpose_name,
              'states' => ['passed'],
              'label' => 'Bed 3',
              'shared_parent' => 'true'
            }
          }
        }
      end

      before do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_tube)
        bed_labware_lookup(phix_tube)
      end

      it_behaves_like 'a robot'

      context 'with a valid layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed2_barcode' => [target_tube_barcode],
            'bed3_barcode' => [phix_tube_barcode]
          }
        end

        context 'and related labwares' do
          let(:target_tube_parents) { [source_plate, phix_tube] }

          it { is_expected.to be_valid }

          context 'but in the wrong state' do
            let(:source_plate_state) { 'pending' }

            it { is_expected.not_to be_valid }
          end

          context 'but of the wrong purpose' do
            let(:source_purpose) { 'Expected plate purpose' }
            let(:source_purpose_name) { 'Invalid plate purpose' }

            it { is_expected.not_to be_valid }
          end
        end

        context 'and unrelated labwares' do
          let(:target_tube_parents) { [create(:plate)] }

          it { is_expected.not_to be_valid }
        end

        context 'and multiple transfers' do
          let(:source_purpose) { source_purpose_name }
          let(:target_purpose) { target_tube_purpose_name }
          let(:robot_spec) do
            {
              'name' => 'robot_name',
              'beds' => {
                'bed1_barcode' => {
                  'purpose' => source_purpose,
                  'states' => ['passed'],
                  'label' => 'Bed 1'
                },
                'bed2_barcode' => {
                  'purpose' => target_purpose,
                  'states' => ['pending'],
                  'label' => 'Bed 2',
                  'parents' => %w[bed1_barcode bed5_barcode],
                  'target_state' => 'passed'
                },
                'bed3_barcode' => {
                  'purpose' => source_purpose,
                  'states' => ['passed'],
                  'label' => 'Bed 3'
                },
                'bed4_barcode' => {
                  'purpose' => target_purpose,
                  'states' => ['pending'],
                  'label' => 'Bed 4',
                  'parents' => %w[bed3_barcode bed5_barcode],
                  'target_state' => 'passed'
                },
                'bed5_barcode' => {
                  'purpose' => phix_tube_purpose_name,
                  'states' => ['passed'],
                  'label' => 'Bed 5',
                  'shared_parent' => 'true'
                }
              }
            }
          end

          let(:target_tube_parents) { [source_plate, phix_tube] }

          let(:source_plate_2) do
            create :plate, barcode_number: 5, purpose_name: source_purpose_name, state: source_plate_state
          end
          let(:source_plate_2_barcode) { source_plate_2.human_barcode }

          let(:target_tube_2_parents) { [source_plate_2, phix_tube] }
          let(:target_tube_2) do
            create :tube,
                   purpose_name: target_tube_purpose_name,
                   barcode_number: 6,
                   state: target_tube_state,
                   parents: target_tube_2_parents
          end
          let(:target_tube_2_barcode) { target_tube_2.human_barcode }

          before do
            bed_labware_lookup(source_plate)
            bed_labware_lookup(target_tube)
            bed_labware_lookup(source_plate_2)
            bed_labware_lookup(target_tube_2)
            bed_labware_lookup(phix_tube)
          end

          context 'with a valid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [source_plate_2_barcode],
                'bed4_barcode' => [target_tube_2_barcode],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            context 'and related labwares' do
              it { is_expected.to be_valid }
            end
          end

          context 'with an invalid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [source_plate_2_barcode],
                'bed4_barcode' => [],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            it { is_expected.not_to be_valid }
          end

          context 'with an invalid layout' do
            let(:scanned_layout) do
              {
                'bed1_barcode' => [source_plate_barcode],
                'bed2_barcode' => [target_tube_barcode],
                'bed3_barcode' => [],
                'bed4_barcode' => [],
                'bed5_barcode' => [phix_tube_barcode]
              }
            end

            it { is_expected.to be_valid }
          end
        end
      end
    end

    context 'a robot with grandchildren' do
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose_name,
              'states' => ['passed'],
              'label' => 'Bed 1'
            },
            'bed2_barcode' => {
              'purpose' => 'target_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 2',
              'parent' => 'bed1_barcode',
              'target_state' => 'passed'
            },
            'bed3_barcode' => {
              'purpose' => 'target2_plate_purpose',
              'states' => ['pending'],
              'label' => 'Bed 3',
              'parent' => 'bed2_barcode',
              'target_state' => 'passed'
            }
          }
        }
      end

      let(:grandchild_purpose_name) { 'target2_plate_purpose' }
      let(:grandchild_purpose_uuid) { SecureRandom.uuid }
      let(:grandchild_barcode) { grandchild_plate.human_barcode }
      let(:grandchild_plate) do
        create :plate,
               purpose_name: grandchild_purpose_name,
               purpose_uuid: grandchild_purpose_uuid,
               parents: [target_plate],
               barcode_number: 3
      end

      before(:each) do
        bed_labware_lookup(source_plate)
        bed_labware_lookup(target_plate)
        bed_labware_lookup(grandchild_plate)
      end

      context 'and the correct layout' do
        let(:scanned_layout) do
          {
            'bed1_barcode' => [source_plate_barcode],
            'bed2_barcode' => [target_plate_barcode],
            'bed3_barcode' => [grandchild_barcode]
          }
        end

        it { is_expected.to be_valid }
      end
    end

    describe 'verify robot' do
      let(:robot_spec) do
        {
          'name' => 'robot_name',
          'verify_robot' => true,
          'beds' => {
            'bed1_barcode' => {
              'purpose' => source_purpose_name,
              'states' => ['passed'],
              'label' => 'Bed 7'
            }
          }
        }
      end

      before { bed_labware_lookup(source_plate) }

      context 'without metadata' do
        let(:source_plate) do
          create :plate, barcode_number: '123', purpose_name: source_purpose_name, state: 'passed'
        end

        it 'is invalid' do
          expect(robot.verify(bed_labwares: { 'bed1_barcode' => [source_plate.human_barcode] })).not_to be_valid
        end
      end

      context 'without plate' do
        it 'is invalid' do
          bed_labware_lookup_with_barcode('dodgy_barcode', [])
          expect(robot.verify(bed_labwares: { 'bed1_barcode' => ['dodgy_barcode'] })).not_to be_falsey
        end
      end

      context 'with metadata' do
        let(:source_plate) do
          create :plate,
                 barcode_number: '123',
                 purpose_name: source_purpose_name,
                 state: 'passed',
                 custom_metadatum_collection: custom_metadatum_collection
        end

        it "is invalid if the barcode isn't recorded" do
          expect(
            robot.verify(
              bed_labwares: {
                'bed1_barcode' => [source_plate.human_barcode]
              },
              robot_barcode: 'robot_barcode'
            )
          ).not_to be_valid
        end

        context 'if barcodes differ' do
          let(:metadata) { { 'other_key' => 'value', 'created_with_robot' => 'other_robot' } }

          it 'is invalid' do
            expect(
              robot.verify(
                bed_labwares: {
                  'bed1_barcode' => [source_plate.human_barcode]
                },
                robot_barcode: 'robot_barcode'
              )
            ).not_to be_valid
          end
        end

        context 'if barcodes match' do
          let(:metadata) { { 'other_key' => 'value', 'created_with_robot' => 'robot_barcode' } }

          it 'is valid' do
            expect(
              robot.verify(
                bed_labwares: {
                  'bed1_barcode' => [source_plate.human_barcode]
                },
                robot_barcode: 'robot_barcode'
              )
            ).to be_valid
          end
        end
      end
    end
  end

  describe 'require robot' do
    let(:robot_spec) do
      {
        'name' => 'robot_name',
        'verify_robot' => false,
        'require_robot' => true,
        'beds' => {
          'bed1_barcode' => {
            'purpose' => source_purpose_name,
            'states' => ['passed'],
            'label' => 'Bed 7'
          }
        }
      }
    end

    before { bed_labware_lookup(source_plate) }

    it 'is invalid if the robot barcode is not scanned - nil' do
      expect(robot.verify(robot_barcode: nil)).not_to be_valid
    end

    it 'is invalid if the robot barcode is not scanned - empty string' do
      expect(robot.verify(robot_barcode: '')).not_to be_valid
    end

    it 'is valid if the robot barcode is scanned' do
      expect(robot.verify(robot_barcode: 'robot_barcode')).to be_valid
    end
  end

  describe '#perform_transfer' do
    let(:robot_spec) do
      {
        'name' => 'bravo LB End Prep',
        'layout' => 'bed',
        'verify_robot' => true,
        'beds' => {
          '580000014851' => {
            'purpose' => 'LB End Prep',
            'states' => ['started'],
            'label' => 'Bed 14',
            'target_state' => 'passed'
          }
        }
      }
    end
    let(:target_plate_state) { 'started' }

    let(:plate) do
      create :plate,
             barcode_number: '123',
             purpose_uuid: 'lb_end_prep_uuid',
             purpose_name: 'LB End Prep',
             state: target_plate_state
    end

    let(:state_changes_attributes) do
      [
        {
          contents: nil,
          customer_accepts_responsibility: false,
          reason: 'Robot bravo LB End Prep started',
          target_state: 'passed',
          target_uuid: plate.uuid,
          user_uuid: user_uuid
        }
      ]
    end

    before do
      create :purpose_config, uuid: 'lb_end_prep_uuid', state_changer_class: 'StateChangers::PlateStateChanger'
      bed_labware_lookup(plate)
    end

    it 'performs transfer from started to passed' do
      expect_state_change_creation

      robot.perform_transfer('580000014851' => [plate.human_barcode])
    end

    context 'if the bed is unexpectedly invalid' do
      let(:target_plate_state) { 'passed' }

      it 'raises a bed error in the event of last-minute errors' do
        expect { robot.perform_transfer('580000014851' => [plate.human_barcode]) }.to raise_error(Robots::Bed::BedError)
      end
    end
  end

  describe '#start_button_message' do
    let(:robot_spec) do
      {
        'name' => 'robot_name',
        'beds' => {
          'bed1_barcode' => {
            'purpose' => source_purpose_name,
            'states' => ['passed'],
            'label' => 'Bed 1'
          }
        }
      }
    end

    it 'returns the correct message when the robot does not have a start_button_text' do
      robot = described_class.new(robot_spec)
      expect(robot.start_button_message).to eq("Start the #{robot.name}")
    end

    it 'returns the robots start_button_text when present' do
      robot = described_class.new(robot_spec.merge(start_button_text: 'Be different'))
      expect(robot.start_button_message).to eq('Be different')
    end
  end
end

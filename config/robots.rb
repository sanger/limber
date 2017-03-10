# frozen_string_literal: true
require 'robot_configuration'

ROBOT_CONFIG = RobotConfiguration::Register.configure do
  # Simple robots and bravo robots both transfer a single 'passed' source plate to a single 'pending'
  # destination plate. They pass the target plate
  # Simple robots can transition to started if their second argument is 'started'

  # Custom robots are configured manually

  robot_scope = self

  bravo_robot do
    from 'LB Cherrypick', bed(7)
    to 'LB Shear', bed(9)
  end

  bravo_robot do
    from 'LB Shear', bed(9)
    to 'LB Post Shear', bed(7)
  end

  bravo_robot 'started' do
    from 'LB Post Shear', bed(4)
    to 'LB End Prep', bed(14)
  end

  custom_robot('bravo-lb-end-prep',
               name: 'bravo LB End Prep',
               layout: 'bed',
               verify_robot: true,
               beds: {
                 robot_scope.bed(7).barcode => { purpose: 'LB End Prep', states: ['started'], label: 'Bed 14', target_state: 'passed' }
               })

  bravo_robot do
    from 'LB End Prep', bed(7)
    to 'LB Lib PCR', bed(6)
  end

  custom_robot('lib-pcr-purification',
               name: 'bravo LB Lib PCR => LB Lib PCR XP',
               layout: 'bed',
               verify_robot: false,
               beds: {
                 robot_scope.bed(1).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 1' },
                 robot_scope.bed(9).barcode  => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 9', parent: robot_scope.bed(1).barcode, target_state: 'passed' },
                 robot_scope.bed(2).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 2' },
                 robot_scope.bed(10).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 10', parent: robot_scope.bed(2).barcode, target_state: 'passed' },
                 robot_scope.bed(3).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 3' },
                 robot_scope.bed(11).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 11', parent: robot_scope.bed(3).barcode, target_state: 'passed' },
                 robot_scope.bed(4).barcode  => { purpose: 'LB Lib PCR',    states: ['passed'],  label: 'Bed 4' },
                 robot_scope.bed(12).barcode => { purpose: 'LB Lib PCR-XP', states: ['pending'], label: 'Bed 12', parent: robot_scope.bed(4).barcode, target_state: 'passed' }
               })
end

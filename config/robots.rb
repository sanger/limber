# frozen_string_literal: true
require 'robot_configuration'

ROBOT_CONFIG = RobotConfiguration::Register.configure do
  # Simple robots and bravo robots both transfer a single 'passed' source plate to a single 'pending'
  # destination plate. They pass the target plate
  # Simple robots can transition to started if their second argument is 'started'

  # Custom robots are configured manually

  bravo_robot do
    from 'LB Cherrypick', bed(7)
    to 'LB Shear', bed(9)
  end

  bravo_robot do
    from 'LB Shear', bed(9)
    to 'LB Post Shear', bed(7)
  end

  bravo_robot do
    from 'LB Post Shear', bed(4)
    to 'LB End Prep', bed(14)
  end

  # bravo_robot do
  #   to 'LB End Prep', bed(7)
  # end

  bravo_robot do
    from 'LB End Prep', bed(14)
    to 'LB Lib PCR', bed(6)
  end

end

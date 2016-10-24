BED = ['580000000793', '580000001806', '580000002810', '580000003824', '580000004838', '580000005842', '580000006856', '580000007860', '580000008874', '580000009659', '580000010815', '580000011829', '580000012833']
CAR = {
  :c13 => '580000013847',
  :c23 => '580000023860',
  :c43 => '580000043677',
  :c45 => '580000045695'
}

require './lib/robot_configuration'

ROBOT_CONFIG = RobotConfiguration::Register.configure do


  # Simple robots and bravo robots both transfer a single 'passed' source plate to a single 'pending'
  # destination plate. They start the target plate
  # fast bravo robots transition straight to passed.
  # Simple robots can transition straight to passed if their second argument is 'passed'

  # Custom robots are configured manually

  # Shared Pipeline
  bravo_robot do
    from 'Limber Cherrypicked', bed(7)
    to 'Limber Shear', bed(9)
  end

  bravo_robot do
    from 'Limber Shear', bed(9)
    to 'Limber Post Shear', bed(7)
  end

  bravo_robot do
    from 'Limber Post Shear', bed(4)
    to 'Limber Post Shear XP', car('2,3')
  end

  custom_robot('nx-96-post-shear-to-post-shear-xp',{
    :name => 'nx-96 Post-Shear => Post-Shear XP',
    :layout => 'bed',
    :beds => {
       BED[1]   => {:purpose => 'Limber Post Shear',    :states => ['passed'],  :label => 'Bed 1'},
       BED[9]   => {:purpose => 'Limber Post Shear XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'passed'},
       BED[2]   => {:purpose => 'Limber Post Shear',    :states => ['passed'],  :label => 'Bed 2'},
       BED[10]  => {:purpose => 'Limber Post Shear XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'passed'},
       BED[3]   => {:purpose => 'Limber Post Shear',    :states => ['passed'],  :label => 'Bed 3'},
       BED[11]  => {:purpose => 'Limber Post Shear XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'passed'},
       BED[4]   => {:purpose => 'Limber Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
       BED[12]  => {:purpose => 'Limber Post Shear XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'passed'}
    }
  })

  bravo_robot do
    from 'Limber Post Shear XP', bed(7)
    to 'Limber AL Libs', car('4,3')
  end

  bravo_robot do
    from 'Limber AL Libs', bed(4)
    to 'Limber Lib PCR', bed(6)
  end


  custom_robot("nx-96-lib-pcr-to-lib-pcr-xp",{
    :name => "Lib PCR => Lib PCR XP",
    :layout => 'bed',
    :beds   => {
      BED[1]   => {:purpose => "Limber Lib PCR",    :states => ["passed"],  :label => "Bed 1"},
      BED[9]   => {:purpose => "Limber Lib PCR-XP", :states => ["pending"], :label => "Bed 9", :parent =>BED[1], :target_state => "passed"},
      BED[2]   => {:purpose => "Limber Lib PCR",    :states => ["passed"],  :label => "Bed 2"},
      BED[10]  => {:purpose => "Limber Lib PCR-XP", :states => ["pending"], :label => "Bed 10", :parent =>BED[2], :target_state => "passed"},
      BED[3]   => {:purpose => "Limber Lib PCR",    :states => ["passed"],  :label => "Bed 3"},
      BED[11]  => {:purpose => "Limber Lib PCR-XP", :states => ["pending"], :label => "Bed 11", :parent =>BED[3], :target_state => "passed"},
      BED[4]   => {:purpose => "Limber Lib PCR",    :states => ["passed"],  :label => "Bed 4"},
      BED[12]  => {:purpose => "Limber Lib PCR-XP", :states => ["pending"], :label => "Bed 12", :parent =>BED[4], :target_state => "passed"}
    }
  })

  simple_robot("nx-96") do
    from "Limber Lib PCR-XP", bed(1)
    to "Limber QC", bed(9)
  end

  # Limber Pipeline

  custom_robot("nx-8-lib-pcr-xp-to-isch-lib-pool",{
    :name   => "nx-8 Lib PCR-XP => Limber Lib Pool",
    :layout => "bed",
    :beds   => {
      BED[2]  => {:purpose => "Lib PCR-XP", :states => ["qc_complete"], :child=>BED[4], :label => 'Bed 2 (Source 1)'},
      BED[5]  => {:purpose => "Lib PCR-XP", :states => ["qc_complete"], :child=>BED[4], :label => 'Bed 5 (Source 2)'},
      BED[3]  => {:purpose => "Lib PCR-XP", :states => ["qc_complete"], :child=>BED[4], :label => 'Bed 3 (Source 3)'},
      BED[6]  => {:purpose => "Lib PCR-XP", :states => ["qc_complete"], :child=>BED[4], :label => 'Bed 6 (Source 4)'},
      BED[4]  => {
        :purpose => "Limber lib pool",
        :states => ["pending","started"],
        :parents =>[BED[2],BED[5],BED[3],BED[6],BED[2],BED[5],BED[3],BED[6]],
        :target_state => "passed",
        :label => 'Bed 4 (Destination)'
      }
    },
    :destination_bed => BED[4],
    :class => "Robots::PoolingRobot"
  })


  simple_robot('nx-8') do
    from 'Limber lib pool', bed(2)
    to 'Limber hyb', bed(4)
  end

  bravo_robot do
    from 'Limber hyb', car('1,3')
    to 'Limber cap lib', bed(4)
  end

  bravo_robot do
    from 'Limber cap lib', bed(4)
    to 'Limber cap lib PCR', car('4,5')
  end

  simple_robot('nx-96') do
    from 'Limber cap lib PCR', bed(1)
    to 'Limber cap lib PCR-XP', bed(9)
  end

  simple_robot('nx-8') do
    from 'Limber cap lib PCR-XP', bed(1)
    to 'Limber cap lib pool', bed(2)
  end


  # Strip Tube Pipeline (HiSeqX)

  simple_robot('nx-8') do
    from 'Lib PCR-XP', bed(4), 'qc_complete'
    to 'Lib Norm', bed(5)
  end

  simple_robot('nx-8') do
    from 'Lib Norm',  bed(4), 'qc_complete'
    to 'Lib Norm 2', bed(5)
  end

  simple_robot('nx-8') do
    from 'Lib Norm 2',  bed(4)
    to 'Lib Norm 2 Pool', bed(5)
  end

  simple_robot('nx-96') do
    from 'Lib Norm', bed(1)
    to 'Lib Norm QC', bed(9)
  end

end


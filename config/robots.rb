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
    from 'Cherrypicked', bed(7)
    to 'Shear', bed(9)
  end

  bravo_robot do
    from 'Shear', bed(9)
    to 'Post Shear', bed(7)
  end

  bravo_robot do
    from 'Post Shear', bed(4)
    to 'Post Shear XP', car('2,3')
  end

  custom_robot('nx-96-post-shear-to-post-shear-xp',{
    :name => 'nx-96 Post-Shear => Post-Shear XP',
    :layout => 'bed',
    :beds => {
       BED[1]   => {:purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 1'},
       BED[9]   => {:purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'passed'},
       BED[2]   => {:purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 2'},
       BED[10]  => {:purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'passed'},
       BED[3]   => {:purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 3'},
       BED[11]  => {:purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'passed'},
       BED[4]   => {:purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
       BED[12]  => {:purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'passed'}
    }
  })

  bravo_robot do
    from 'Post Shear XP', bed(7)
    to 'AL Libs', car('4,3')
  end

  bravo_robot do
    from 'AL Libs', bed(4)
    to 'Lib PCR', bed(6)
  end

  custom_robot('nx-96',{
    :name => 'Lib PCR => Lib PCR XP',
    :layout => 'bed',
    :beds   => {
      BED[1]   => {:purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 1'},
      BED[9]   => {:purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'passed'},
      BED[2]   => {:purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 2'},
      BED[10]  => {:purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'passed'},
      BED[3]   => {:purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 3'},
      BED[11]  => {:purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'passed'},
      BED[4]   => {:purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 4'},
      BED[12]  => {:purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'passed'}
    }
  })

  simple_robot('nx-96') do
    from 'Lib PCR-XP', bed(1)
    to 'Lib PCR-XP QC', bed(9)
  end

  # ISCH Pipeline

  custom_robot('nx-8-pre-cap-pool',{
    :name   => 'nx-8 Lib PCR-XP => ISCH Lib Pool',
    :layout => 'bed',
    :beds   => {
      BED[2]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[4]},
      BED[5]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[4]},
      BED[3]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[4]},
      BED[6]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[4]},
      BED[4]  => {
        :purpose => 'ISCH lib pool',
        :states => ['pending','started'],
        :parents =>[BED[2],BED[5],BED[3],BED[6],BED[2],BED[5],BED[3],BED[6]],
        :target_state => 'passed'
      }
    },
    :destination_bed => BED[5],
    :class => 'Robots::PoolingRobot'
  })

  simple_robot('nx-8') do
    from 'ISCH lib pool', bed(2)
    to 'ISCH hyb', bed(4)
  end

  bravo_robot do
    from 'ISCH hyb', car('1,3')
    to 'ISCH cap lib', bed(4)
  end

  bravo_robot do
    from 'ISCH cap lib', bed(4)
    to 'ISCH cap lib PCR', car('4,5')
  end

  simple_robot('nx-96') do
    from 'ISCH cap lib PCR', bed(1)
    to 'ISCH cap lib PCR-XP', bed(9)
  end

  simple_robot('nx-8') do
    from 'ISCH cap lib PCR-XP', bed(1)
    to 'ISCH cap lib pool', bed(2)
  end

  # PCR Free Pipeline

  bravo_robot do
    from 'PF Cherrypicked', bed(7)
    to 'PF Shear', bed(9)
  end

  bravo_robot do
    from 'PF Shear', bed(9)
    to 'PF Post Shear', bed(7)
  end

  bravo_robot('started') do
    from 'PF Post Shear', bed(4)
    to 'PF Post Shear XP', car('2,3')
  end

  custom_robot('nx-96-pf-post-shear-to-pf-post-shear-xp',{
    :name => 'nx-96 PF Post-Shear => PF Post-Shear XP',
    :layout => 'bed',
    :beds => {
       BED[1]   => {:purpose => 'PF Post Shear',    :states => ['passed'],  :label => 'Bed 1'},
       BED[9]   => {:purpose => 'PF Post Shear XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'},
       BED[2]   => {:purpose => 'PF Post Shear',    :states => ['passed'],  :label => 'Bed 2'},
       BED[10]  => {:purpose => 'PF Post Shear XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'started'},
       BED[3]   => {:purpose => 'PF Post Shear',    :states => ['passed'],  :label => 'Bed 3'},
       BED[11]  => {:purpose => 'PF Post Shear XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'started'},
       BED[4]   => {:purpose => 'PF Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
       BED[12]  => {:purpose => 'PF Post Shear XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'started'}
    }
  })

  custom_robot('bravo-pf-post-shear-xp-prep',{
    :name => 'Bravo PF Post Shear XP Preparation',
    :layout => 'bed',
    :beds => {
      BED[5] => {:purpose => 'PF Post Shear XP',    :states => ['started'],  :label => 'Bed 5', :target_state => 'passed'}
    }
  })

  custom_robot('bravo-pf-post-shear-xp-to-pf-lib-xp',{
    :name => 'Bravo PF Post Shear XP to PF Lib XP',
    :layout => 'bed',
    :beds => {
      CAR[:c13] => {:purpose => 'PF Post Shear XP', :states => ['passed'],  :label => 'Carousel 1,3' },
      BED[6]    => {:purpose => 'PF Lib',           :states => ['pending'], :label => 'Bed 6', :target_state=>'passed', :parent => CAR[:c13] },
      CAR[:c43] => {:purpose => 'PF Lib XP',        :states => ['pending'], :label => 'Carousel 4,3', :target_state=>'passed', :parent => BED[6] }
    }
  })

  bravo_robot do
    from 'PF Lib XP', bed(4)
    to 'PF Lib XP2', car('2,3')
  end

  custom_robot('pf-lib-xp2-to-pf-miseq-qc',{
    :name => 'PF Lib XP2 to PF MiSeq QC',
    :layout => 'bed',
    :beds => {
      BED[4] => {:purpose => 'PF Lib XP2',  :states => ['passed'],  :label => 'Bed 4' },
      BED[7] => {:purpose => 'PF MiSeq QC', :secondary_purposes => ['PF MiSeq Stock'], :states => ['pending'], :label => 'Bed 7', :target_state=>'passed', :parent => BED[4] }
    },
    :class => 'Robots::SharedBedRobot'
  })

  bravo_robot do
    from 'PF Lib XP2', bed(4), 'qc_complete'
    to 'PF EM Pool', bed(7)
  end

  bravo_robot do
    from 'PF EM Pool', bed(4)
    to 'PF EM Pool QC', bed(9)
  end

  bravo_robot do
    from 'PF EM Pool', bed(4), 'qc_complete'
    to 'PF Lib Norm', bed(7)
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


#BED = ['580000000793', '580000001806', '580000002810', '580000003824', '580000004838', '580000005842', '580000006856', '580000007860', '580000008874', '580000009659', '580000010815', '580000011829', '580000012833']
#CAR = {
#  :c23 => '580000023860',
#  :c43 => '580000043677'
#}

### REVIEW: Pulldown config contains 1 digit more for every barcode
BED = ['5800000007932', '5800000018068', '5800000028104', '5800000038240', '5800000048386', '5800000058422', '5800000068568', '5800000078604', '5800000088740', '5800000096592', '5800000108158', '5800000118294', '5800000128330']
CAR = {
  :c13 => '5800000138476',
  :c23 => '5800000238602',
  :c43 => '5800000436770'
}


ROBOT_CONFIG = {
  ### From pulldown
  'nx8-pre-cap-pool' => {
    :name   => 'NX8 Lib PCR-XP to ISCH Lib Pool',
    :layout => 'bed',
    :beds   => {
      BED[2]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[5]},
      BED[6]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[5]},
      BED[3]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[5]},
      BED[7]  => {:purpose => 'Lib PCR-XP', :states => ['qc_complete'], :child=>BED[5]},
      BED[5]  => {
        :purpose => 'ISCH lib pool',
        :states => ['pending','started'],
        :parents =>[BED[2],BED[6],BED[3],BED[7],BED[2],BED[6],BED[3],BED[7]],
        :target_state => 'nx_in_progress'
      }
    },
    :destination_bed => BED[5],
    :class => 'Robots::PoolingRobot'
  },
  'nx8-pre-hyb-pool' => {
    :name   => 'NX8 ISCH Lib Pool to Hyb',
    :layout => 'bed',
    :beds   => {
      BED[5]  => {:purpose => 'ISCH lib pool', :states => ['passed'], :child=>BED[6]},
      BED[6]  => {
        :purpose => 'ISCH hyb',
        :states => ['pending'],
        :parents =>[BED[5]],
        :target_state => 'started'
      }
    }
  },
  'bravo-cap-wash' => {
    :name   => 'Bravo ISCH hyb to ISCH cap lib',
    :layout => 'bed',
    :beds   => {
      BED[4]  => {:purpose => 'ISCH hyb', :states => ['passed'], :child=>CAR[:c13]},
      CAR[:c13]  => {
        :purpose => 'ISCH cap lib',
        :states => ['pending'],
        :parents =>[BED[4]],
        :target_state => 'started'
      }
    }
  },
  'bravo-post-cap-pcr-setup' => {
    :name   => 'Bravo ISCH cap lib to ISCH cap lib PCR',
    :layout => 'bed',
    :beds   => {
      BED[4]  => {:purpose => 'ISCH cap lib', :states => ['passed'], :child=>BED[5]},
      BED[5]  => {
        :purpose => 'ISCH cap lib PCR',
        :states => ['pending'],
        :parents =>[BED[4]],
        :target_state => 'started'
      }
    }
  },
  'bravo-post-cap-pcr-cleanup' => {
    :name   => 'Bravo ISCH cap lib PCR to ISCH cap lib PCR-XP',
    :layout => 'bed',
    :beds   => {
      BED[4]  => {:purpose => 'ISCH cap lib PCR', :states => ['passed'], :child=>CAR[:c23]},
      CAR[:c23]  => {
        :purpose => 'ISCH cap lib PCR-XP',
        :states => ['pending'],
        :parents =>[BED[4]],
        :target_state => 'started'
      }
    }
  },
  'nx8-post-cap-lib-pool' => {
    :name   => 'NX8 ISCH cap lib PCR-XP to ISCH cap lib pool',
    :layout => 'bed',
    :beds   => {
      BED[1]  => {:purpose => 'ISCH cap lib PCR-XP', :states => ['passed'], :child=>BED[9]},
      BED[9]  => {
        :purpose => 'ISCH cap lib pool',
        :states => ['pending'],
        :parents =>[BED[1]],
        :target_state => 'started'
      }
    }
  },

  ### Illumina b


  'illumina_b' => {
    'cherrypick-to-shear' => {
      :name => 'Illumina A nx-96 Cherrypick to Shear',
      :layout => 'bed',
      :beds => {
        BED[4]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Bed 4'},
        BED[6]  => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Bed 6', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'shear-post-shear' => {
      :name => 'Illumina A Bravo Shear to Post-Shear',
      :layout => 'bed',
      :beds => {
        BED[4] => {:order=>1, :purpose => 'Shear',         :states => ['passed'],  :label => 'Bed 4'},
        BED[6] => {:order=>2, :purpose => 'Post Shear',    :states => ['pending'], :label => 'Bed 5',    :parent =>BED[4], :target_state => 'started' }
      }
    },
    'post-shear-post-shear-xp' => {
      :name => 'Illumina A nx-96 Post-Shear to Post-Shear XP',
      :layout => 'bed',
      :beds => {
        BED[1]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 1'},
        BED[9]  => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'},
        BED[2]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 2'},
        BED[10] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'started'},
        BED[3]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 3'},
        BED[11] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'started'},
        BED[4]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
        BED[12] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'lib-pcr-xp-lib-pcr-xp-qc' => {
      :name => 'Illumina A nx-96 Lib-PCR XP to Lib-PCR XP QC',
      :layout => 'bed',
      :beds => {
        BED[1] => {:order=>1, :purpose => 'Lib PCR-XP',    :states => ['passed'],  :label => 'Bed 1'},
        BED[9] => {:order=>2, :purpose => 'Lib PCR-XP QC', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'}
      }
    },
    'fx' => {
      :name => 'Illumina A Bravo Post-Shear XP to Al Libs',
      :layout => 'bed',
      :beds   => {
        BED[7]    => {:order=>1, :purpose => 'Post Shear XP', :states => ['passed'],  :label => 'Bed 7'},
        CAR[:c43] => {:order=>2, :purpose => 'AL Libs',       :states => ['pending'], :label => 'Carousel 4,3', :parent =>BED[7], :target_state => 'started'}
      }
    },
    'fx-add-tags' => {
      :name => 'Illumina A Bravo Add Tags',
      :layout => 'bed',
      :beds   => {
        BED[4] => {:purpose => 'AL Libs', :states => ['started'], :label => 'Bed 4'},
        BED[6] => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>BED[4], :target_state => 'started_fx', :label => 'Bed 6'}
      }
    },
    'nx-96' => {
      :name => 'Illumina A nx-96',
      :layout => 'bed',
      :beds   => {
        BED[1]   => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 1'},
        BED[9]   => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'},
        BED[2]   => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 2'},
        BED[10]  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'started'},
        BED[3]   => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 3'},
        BED[11]  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'started'},
        BED[4]   => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Bed 4'},
        BED[12]  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'started'}
      }
    }
  }
}
ROBOT_CONFIG['illumina_a']=ROBOT_CONFIG['illumina_b']

LOCATION_PIPELINES = {
  'Library creation freezer'                 =>'illumina_b',
  'Pulldown freezer'                         =>'illumina_a',
  'Illumina high throughput freezer'         =>'illumina_b'
}

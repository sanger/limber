#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
BED = ['580000000793', '580000001806', '580000002810', '580000003824', '580000004838', '580000005842', '580000006856', '580000007860', '580000008874', '580000009659', '580000010815', '580000011829', '580000012833']
CAR = {
  :c13 => '580000013847',
  :c23 => '580000023860',
  :c43 => '580000043677'
}

ROBOT_CONFIG = {

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

  'cherrypick-to-shear' => {
    :name => 'nx-96 Cherrypick to Shear',
    :layout => 'bed',
    :beds => {
      BED[4]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Bed 4'},
      BED[6]  => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Bed 6', :parent =>BED[4], :target_state => 'started'}
    }
  },
  'shear-post-shear' => {
    :name => 'Bravo Shear to Post-Shear',
    :layout => 'bed',
    :beds => {
      BED[4] => {:order=>1, :purpose => 'Shear',         :states => ['passed'],  :label => 'Bed 4'},
      BED[6] => {:order=>2, :purpose => 'Post Shear',    :states => ['pending'], :label => 'Bed 6',    :parent =>BED[4], :target_state => 'started' }
    }
  },
  'post-shear-post-shear-xp' => {
    :name => 'Bravo Post-Shear to Post-Shear XP',
    :layout => 'bed',
    :beds => {
      BED[4]    => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
      CAR[:c23] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Carousel 2,3', :parent =>BED[4], :target_state => 'started'}
    }
  },
  'post-shear-post-shear-xp-nx' => {
    :name => 'nx-96 Post-Shear to Post-Shear XP',
    :layout => 'bed',
    :beds => {
       BED[1]   => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 1'},
       BED[9]   => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'},
       BED[2]   => {:order=>3, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 2'},
       BED[10]  => {:order=>4, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 10', :parent =>BED[2], :target_state => 'started'},
       BED[3]   => {:order=>5, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 3'},
       BED[11]  => {:order=>6, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 11', :parent =>BED[3], :target_state => 'started'},
       BED[4]   => {:order=>7, :purpose => 'Post Shear',    :states => ['passed'],  :label => 'Bed 4'},
       BED[12]  => {:order=>8, :purpose => 'Post Shear XP', :states => ['pending'], :label => 'Bed 12', :parent =>BED[4], :target_state => 'started'}
    }
  },
  'lib-pcr-xp-lib-pcr-xp-qc' => {
    :name => 'nx-96 Lib-PCR XP to Lib-PCR XP QC',
    :layout => 'bed',
    :beds => {
      BED[1] => {:order=>1, :purpose => 'Lib PCR-XP',    :states => ['passed'],  :label => 'Bed 1'},
      BED[9] => {:order=>2, :purpose => 'Lib PCR-XP QC', :states => ['pending'], :label => 'Bed 9', :parent =>BED[1], :target_state => 'started'}
    }
  },
  'fx' => {
    :name => 'Bravo Post-Shear XP to Al Libs',
    :layout => 'bed',
    :beds   => {
      BED[7]    => {:order=>1, :purpose => 'Post Shear XP', :states => ['passed'],  :label => 'Bed 7'},
      CAR[:c43] => {:order=>2, :purpose => 'AL Libs',       :states => ['pending'], :label => 'Carousel 4,3', :parent =>BED[7], :target_state => 'started'}
    }
  },
  'fx-add-tags' => {
    :name => 'Bravo Transfer to tag plate',
    :layout => 'bed',
    :beds   => {
      BED[4] => {:purpose => 'AL Libs', :states => ['started'], :label => 'Bed 4'},
      BED[6] => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>BED[4], :target_state => 'started_fx', :label => 'Bed 6'}
    }
  },
  'nx-96' => {
    :name => 'Lib PCR => Lib PCR XP',
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
  },
  'pcr-xp-lib-norm' => {
    :name => 'NX8 PCR-XP => Lib Norm',
    :layout => 'bed',
    :beds => {
      BED[4] => {:order=>1, :purpose => 'Lib PCR-XP',  :states => ['qc_complete'],  :label => 'Bed 4'},
      BED[5] => {:order=>2, :purpose => 'Lib Norm',    :states => ['pending'], :label => 'Bed 5', :parent =>BED[4], :target_state => 'started' }
    }
  },
  'lib-norm-lib-norm-2' => {
    :name => 'NX8 Lib Norm => Lib Norm 2',
    :layout => 'bed',
    :beds => {
      BED[4] => {:order=>1, :purpose => 'Lib Norm',   :states => ['qc_complete'],  :label => 'Bed 4'},
      BED[5] => {:order=>2, :purpose => 'Lib Norm 2', :states => ['pending'], :label => 'Bed 5', :parent =>BED[4], :target_state => 'started' }
    }
  },
  'lib-norm-2-lib-norm-2-pool' => {
    :name => 'NX8 Lib Norm 2 => Lib Norm 2 Pool',
    :layout => 'bed',
    :beds => {
      BED[4] => {:order=>1, :purpose => 'Lib Norm 2',      :states => ['passed'],  :label => 'Bed 4'},
      BED[5] => {:order=>2, :purpose => 'Lib Norm 2 Pool', :states => ['pending'], :label => 'Bed 5', :parent =>BED[4], :target_state => 'started' }
    }
  }
}

LOCATION_PIPELINES = {
  'Library creation freezer'                 =>'illumina_b',
  'Pulldown freezer'                         =>'illumina_a',
  'Illumina high throughput freezer'         =>'illumina_b'
}

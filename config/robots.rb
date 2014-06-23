BED = ['580000000793', '580000001806', '580000002810', '580000003824', '580000004838', '580000005842', '580000006856', '580000007860', '580000008874', '580000009659', '580000010815', '580000011829', '580000012833']
CAR = {
  :c23 => '580000023860',
  :c43 => '580000043677'
}

ROBOT_CONFIG = {
  'illumina_b' => {
    'cherrypick-to-shear' => {
      :name => 'Illumina A nx-96 Cherrypick to Shear',
      :layout => 'bed',
      :beds => {
        BED[4]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Cherrypicked Plate'},
        BED[6]  => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Shear Plate', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'shear-post-shear' => {
      :name => 'Illumina A Bravo Shear to Post-Shear',
      :layout => 'bed',
      :beds => {
        BED[4] => {:order=>1, :purpose => 'Shear',         :states => ['passed'],  :label => 'Shear Plate'},
        BED[6] => {:order=>2, :purpose => 'Post Shear',    :states => ['pending'], :label => 'Post Shear Plate',    :parent =>BED[4], :target_state => 'started' }
      }
    },
    'post-shear-post-shear-xp' => {
      :name => 'Illumina A nx-96 Post-Shear to Post-Shear XP',
      :layout => 'bed',
      :beds => {
        BED[1]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[9]  => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[1], :target_state => 'started'},
        BED[2]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[10] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[2], :target_state => 'started'},
        BED[3]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[11] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[3], :target_state => 'started'},
        BED[4]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[12] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'lib-pcr-xp-lib-pcr-xp-qc' => {
      :name => 'Illumina A nx-96 Lib-PCR XP to Lib-PCR XP QC',
      :layout => 'bed',
      :beds => {
        BED[1] => {:order=>1, :purpose => 'Lib PCR-XP',    :states => ['passed'],  :label => 'Post Shear Plate'},
        BED[9] => {:order=>2, :purpose => 'Lib PCR-XP QC', :states => ['pending'], :label => 'Post Shear XP Plate', :parent =>BED[1], :target_state => 'started'}
      }
    },
    'fx' => {
      :name => 'Illumina A Bravo Post-Shear XP to Al Libs',
      :layout => 'bed',
      :beds   => {
        BED[7]    => {:order=>1, :purpose => 'Post Shear XP', :states => ['passed'],  :label => 'Post Shear XP Plate A'},
        CAR[:c43] => {:order=>2, :purpose => 'AL Libs',       :states => ['pending'], :label => 'AL Libs Plate A', :parent =>BED[7], :target_state => 'started'}
      }
    },
    'fx-add-tags' => {
      :name => 'Illumina A Bravo Add Tags',
      :layout => 'bed',
      :beds   => {
        BED[4] => {:purpose => 'AL Libs', :states => ['started']},
        BED[6] => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>BED[4], :target_state => 'started_fx'}
      }
    },
    'nx-96' => {
      :name => 'Illumina A nx-96',
      :layout => 'bed',
      :beds   => {
        BED[1]   => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate A'},
        BED[9]   => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate A', :parent =>BED[1], :target_state => 'started'},
        BED[2]   => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate B'},
        BED[10]  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate B', :parent =>BED[2], :target_state => 'started'},
        BED[3]   => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate C'},
        BED[11]  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate C', :parent =>BED[3], :target_state => 'started'},
        BED[4]   => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate D'},
        BED[12]  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate D', :parent =>BED[4], :target_state => 'started'}
      }
    }
  },



  'illumina_a' => {
    'cherrypick-to-shear' => {
      :name => 'Illumina A nx-96 Cherrypick to Shear',
      :layout => 'bed',
      :beds => {
        BED[4]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Cherrypicked Plate'},
        BED[6]  => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Shear Plate', :parent =>BED[4], :target_state => 'started'}
        # BED[2]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Cherrypicked Plate'},
        # BED[10] => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Shear Plate', :parent =>BED[2], :target_state => 'started'},
        # BED[3]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Cherrypicked Plate'},
        # BED[11] => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Shear Plate', :parent =>BED[3], :target_state => 'started'},
        # BED[4]  => {:order=>1, :purpose => 'Cherrypicked', :states => ['passed'],      :label => 'Cherrypicked Plate'},
        # BED[12] => {:order=>2, :purpose => 'Shear',        :states => ['pending'],     :label => 'Shear Plate', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'shear-post-shear' => {
      :name => 'Illumina A Bravo Shear to Post-Shear',
      :layout => 'bed',
      :beds => {
        BED[4] => {:order=>1, :purpose => 'Shear',         :states => ['passed'],  :label => 'Shear Plate'},
        BED[6] => {:order=>2, :purpose => 'Post Shear',    :states => ['pending'], :label => 'Post Shear Plate',  :parent =>BED[4], :target_state => 'started'}
      }
    },
    'post-shear-post-shear-xp' => {
      :name => 'Illumina A nx-96 Post-Shear to Post-Shear XP',
      :layout => 'bed',
      :beds => {
        BED[1]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[9]  => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[1], :target_state => 'started'},
        BED[2]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[10] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[2], :target_state => 'started'},
        BED[3]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[11] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[3], :target_state => 'started'},
        BED[4]  => {:order=>1, :purpose => 'Post Shear',    :states => ['passed'], :label => 'Post Shear Plate'},
        BED[12] => {:order=>2, :purpose => 'Post Shear XP', :states => ['pending'],     :label => 'Post Shear XP Plate', :parent =>BED[4], :target_state => 'started'}
      }
    },
    'lib-pcr-xp-lib-pcr-xp-qc' => {
      :name => 'Illumina A nx-96 Lib-PCR XP to Lib-PCR XP QC',
      :layout => 'bed',
      :beds => {
        BED[1] => {:order=>1, :purpose => 'Lib PCR-XP',    :states => ['passed'],  :label => 'Post Shear Plate'},
        BED[9] => {:order=>2, :purpose => 'Lib PCR-XP QC', :states => ['pending'], :label => 'Post Shear XP Plate', :parent =>BED[1], :target_state => 'started'}
      }
    },
    'fx' => {
      :name => 'Illumina A Bravo Post-Shear XP to Al Libs',
      :layout => 'bed',
      :beds   => {
        BED[7]    => {:order=>1, :purpose => 'Post Shear XP', :states => ['passed'],  :label => 'Post Shear XP Plate A'},
        CAR[:c43] => {:order=>2, :purpose => 'AL Libs',       :states => ['pending'], :label => 'AL Libs Plate A', :parent =>BED[7], :target_state => 'started'}
      }
    },
    'fx-add-tags' => {
      :name => 'Illumina A Bravo Add Tags',
      :layout => 'bed',
      :beds   => {
        BED[4] => {:purpose => 'AL Libs', :states => ['started']},
        BED[6] => {:purpose => 'Lib PCR', :states => ['pending'], :parent =>BED[4], :target_state => 'started_fx'}
      }
    },
    'nx-96' => {
      :name => 'Illumina A nx-96',
      :layout => 'bed',
      :beds   => {
        BED[1]   => {:order=>1, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate A'},
        BED[9]   => {:order=>2, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate A', :parent =>BED[1], :target_state => 'started'},
        BED[2]   => {:order=>3, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate B'},
        BED[10]  => {:order=>4, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate B', :parent =>BED[2], :target_state => 'started'},
        BED[3]   => {:order=>5, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate C'},
        BED[11]  => {:order=>6, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate C', :parent =>BED[3], :target_state => 'started'},
        BED[4]   => {:order=>7, :purpose => 'Lib PCR',    :states => ['passed'],  :label => 'Lib PCR Plate D'},
        BED[12]  => {:order=>8, :purpose => 'Lib PCR-XP', :states => ['pending'], :label => 'Lib PCR-XP Plate D', :parent =>BED[4], :target_state => 'started'}
      }
    }
  }
}

LOCATION_PIPELINES = {
  'Library creation freezer' =>'illumina_b',
  'Pulldown freezer'         =>'illumina_a'
}

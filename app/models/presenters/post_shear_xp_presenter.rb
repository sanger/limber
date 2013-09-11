module Presenters
  class PostShearXpPresenter < StandardPresenter

    write_inheritable_attribute :robot_controlled_states, {
      :pending => 'post-shear-post-shear-xp'
    }

  end
end

module Presenters
  #
  # Combines PCR rendering (tagged aliquots) with permissive plate creation behavior
  #
  class PcrPermissivePresenter < StandardPresenter
    include Presenters::Statemachine::Permissive

    # Use the tagged aliquot partial from PcrPresenter
    self.aliquot_partial = 'tagged_aliquot'

    # Include the same validators as PermissivePresenter
    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator
  end
end
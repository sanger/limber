# frozen_string_literal: true

require_dependency 'presenters/presenter'

module Presenters
  # Basic core presenter class for tube racks
  # Over time, expect this class to use composition to handle the need for different
  # rack presenters based on the tubes within.
  class TubeRackPresenter
    include Presenters::Presenter
  end
end

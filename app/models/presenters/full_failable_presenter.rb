# frozen_string_literal: true

module Presenters
  class FullFailablePresenter < FailablePresenter
    include Presenters::ExtendedCsv
  end
end

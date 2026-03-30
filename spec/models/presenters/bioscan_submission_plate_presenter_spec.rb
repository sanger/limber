# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::BioscanSubmissionPlatePresenter do
  describe '#active_pipelines' do
    it_behaves_like 'a presenter defining active pipelines as having active requests', lambda { |labware|
      described_class.new(labware:)
    }
  end
end

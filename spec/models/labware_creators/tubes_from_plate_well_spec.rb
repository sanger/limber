# frozen_string_literal: true

require 'spec_helper'
require_relative 'shared_examples'

# TaggingForm creates a plate and applies the given tag templates
RSpec.describe LabwareCreators::TubesFromPlateWell do
  has_a_working_api

  context 'for pre creation' do
    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a plate' do
        let(:parent) { build :plate }

        it { is_expected.to be true }
      end
    end
  end
end

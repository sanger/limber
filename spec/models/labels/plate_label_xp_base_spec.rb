# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Labels::PlateLabelXp, type: :model do
  context 'when creating the label of a plate' do
    let(:labware) { create :v2_plate }
    let(:label) { Labels::PlateLabelXp.new(labware) }
    let(:ancestors_scope) { double('ancestors') }

    before { allow(labware).to receive(:ancestors).and_return(ancestors_scope) }

    context 'when the plate has one stock plate' do
      # TODO: This test was left empty. Made rubocop happy, which means it is
      # now flagged as pending. Which is correct, it is pending.
      it 'displays the stock plate barcode'
    end
  end
end

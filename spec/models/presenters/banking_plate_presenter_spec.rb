# frozen_string_literal: true

require 'rails_helper'

# Test that LRC PBMC Bank plate can enable/disable buttons based on labware
# state. We use StandardPresenter to test this because it is the default
# presenter for plates and it includes a state machine to handle the state.
RSpec.describe Presenters::StandardPresenter do
  before { create :banking_plate_purpose_config }

  let(:purpose_name) { 'banking-plate-purpose' }
  let(:purpose) { create :purpose, name: purpose_name }
  let(:labware) { create :plate, purpose: }
  let(:presenter) { described_class.new(labware:) }

  describe '#csv_file_links' do
    let(:download_in_passed_state_name) { 'Download PBMC Bank Tubes Content Report' }
    let(:download_in_any_state) { 'Download Cellaca 4 Count CSV' }

    context 'when the plate is pending' do
      before { presenter.state = 'pending' }

      it 'excludes the content report link' do
        names = presenter.csv_file_links.map(&:first)
        expect(names).not_to include(download_in_passed_state_name)
      end

      it 'includes cellaca download link' do
        names = presenter.csv_file_links.map(&:first)
        expect(names).to include(download_in_any_state)
      end
    end

    context 'when the plate is passed' do
      it 'includes content report link' do
        names = presenter.csv_file_links.map(&:first)
        expect(names).not_to include(download_in_passed_state_name)
      end

      it 'includes cellaca download link' do
        names = presenter.csv_file_links.map(&:first)
        expect(names).to include(download_in_any_state)
      end
    end
  end
end

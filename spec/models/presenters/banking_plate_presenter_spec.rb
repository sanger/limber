# frozen_string_literal: true

require 'rails_helper'
require 'presenters/banking_plate_presenter'

RSpec.describe Presenters::BankingPlatePresenter do
  has_a_working_api

  before { create :banking_plate_purpose_config }

  let(:purpose_name) { 'banking-plate-purpose' }
  let(:purpose) { create :v2_purpose, name: purpose_name }
  let(:labware) { create :v2_plate, purpose: purpose }
  let(:presenter) { described_class.new(api: api, labware: labware) }

  describe '#csv_file_links' do
    let(:download_in_passed_state_name) { 'Download PBMC Bank Tubes Content Report' }
    let(:download_in_any_state) { 'Download Cellaca LRC PBMC Bank Hamilton 4 Count CSV' }

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

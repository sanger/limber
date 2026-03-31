# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::StockPlateWithSubmissionPresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:labware) { create(:stock_plate, direct_submissions:) }
  let(:direct_submissions) { [] }

  let(:template_uuid) { SecureRandom.uuid }
  let(:submission) { create(:submission, template_uuid:) }

  let(:template) { double(request_type_keys: ['rna_seq']) }

  before do
    allow(Sequencescape::Api::V2::SubmissionTemplate)
      .to receive(:find_by)
      .with(uuid: template_uuid)
      .and_return(template)
  end

  describe '#allow_new_submission?' do
    it 'allows creation of new submissions' do
      expect(presenter.allow_new_submission?).to be true
    end
  end

  describe '#disable_button_for_submission?' do
    context 'when there are pending submissions' do
      let(:direct_submissions) { [create(:submission, state: 'pending')] }

      it 'disables the submission button' do
        expect(presenter.disable_button_for_submission?(submission)).to be true
      end
    end

    context 'when request type already exists on the plate' do
      # rubocop:disable RSpec/VerifiedDoubleReference
      let(:request) { instance_double('Request', request_type_key: 'rna_seq') }
      # rubocop:enable RSpec/VerifiedDoubleReference
      let(:well) { create(:well, coordinate: 'A1') }

      before do
        allow(well).to receive(:active_requests).and_return([request])
        allow(labware).to receive(:wells).and_return([well])
      end

      it 'disables the submission button' do
        expect(presenter.disable_button_for_submission?(submission)).to be true
      end
    end

    context 'when request type is not active on the plate' do
      let(:well) { create(:well, coordinate: 'A1') }

      before do
        allow(well).to receive(:active_requests).and_return([])
        allow(labware).to receive(:wells).and_return([well])
      end

      it 'allows submission' do
        expect(presenter.disable_button_for_submission?(submission)).to be false
      end
    end
  end
end

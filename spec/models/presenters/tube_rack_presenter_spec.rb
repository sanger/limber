# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TubeRackPresenter do
  subject(:presenter) { described_class.new(labware:) }

  let(:purpose_name) { 'TR96' }
  let(:tube_purpose_name) { 'Tube purpose' }
  let(:title) { "#{purpose_name} : #{tube_purpose_name}" }
  let(:state) { 'pending' }
  let(:summary_tab) do
    [
      %w[Barcode DN2T],
      ['Number of tubes', 3],
      ['Rack type', 'TR96'],
      ['Tube type', 'Tube purpose'],
      ['Created on', '2017-06-29']
    ]
  end
  let(:sidebar_partial) { 'default' }
  let(:file_links) { [] }

  let(:labware) { build :tube_rack, purpose_name: purpose_name, tubes: tubes, barcode_number: 2 }

  let(:states) { %w[pending pending pending] }

  let(:tubes) do
    {
      'A1' => create(:v2_tube, priority: 1, purpose_name: tube_purpose_name, state: states[0]),
      'B1' => create(:v2_tube, priority: 3, purpose_name: tube_purpose_name, state: states[1]),
      'C1' => create(:v2_tube, priority: 0, purpose_name: tube_purpose_name, state: states[2])
    }
  end

  let(:warnings) { {} }
  let(:label_class) { 'Labels::PlateLabel' }

  before do
    create(
      :tube_rack_config,
      uuid: labware.purpose.uuid,
      warnings: warnings,
      label_class: label_class,
      file_links: file_links
    )
    create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid')
  end

  it_behaves_like 'a labware presenter'

  describe '#priority' do
    it 'returns the maximum priority of all tubes' do
      expect(presenter.priority).to eq(3)
    end
  end

  describe '#state' do
    context 'everything pending' do
      it 'returns pending' do
        expect(presenter.state).to eq('pending')
      end
    end

    context 'everything failed' do
      let(:states) { %w[failed failed failed] }

      it 'returns failed' do
        expect(presenter.state).to eq('failed')
      end
    end

    context 'mix of passed and failed' do
      let(:states) { %w[passed failed failed] }

      it 'returns passed' do
        expect(presenter.state).to eq('passed')
      end
    end

    context 'mix of passed and cancelled' do
      let(:states) { %w[passed cancelled cancelled] }

      it 'returns passed' do
        expect(presenter.state).to eq('passed')
      end
    end

    context 'mix of failed and cancelled' do
      let(:states) { %w[failed cancelled cancelled] }

      it 'returns failed' do
        expect(presenter.state).to eq('failed')
      end
    end

    context 'mix of other states' do
      let(:states) { %w[passed pending started] }

      it 'returns mixed' do
        expect(presenter.state).to eq('mixed')
      end
    end
  end

  describe '#comment_title' do
    it 'returns the a barcode, purpose and tube purposes' do
      expect(presenter.comment_title).to eq("DN2T - #{purpose_name} : #{tube_purpose_name}")
    end
  end

  describe '#number_of_tubes' do
    it 'returns a count of the number of tubes' do
      expect(presenter.number_of_tubes).to eq(3)
    end
  end

  describe '#csv_file_links' do
    context 'with a default tube rack' do
      it 'returns the expected csv links' do
        expect(presenter.csv_file_links).to eq([])
      end
    end

    context 'with a rack that has multiple links' do
      let(:file_links) do
        [
          { name: 'First type CSV', id: 'first_csv_id' },
          { name: 'Second type CSV', id: 'second_csv_id' },
          { name: 'Third type CSV', id: 'third_csv_id' }
        ]
      end

      it 'returns the expected number of links' do
        expect(presenter.csv_file_links.length).to eq(3)
      end

      it 'formats_the_links' do
        # NOTE: This endpoint doesn't currently exist, but will be added in https://github.com/sanger/limber/issues/795
        # rubocop:todo Layout/LineLength
        # We'll probably want to adjust the behaviour slightly to grab the information based on the contained tube purposes
        # rubocop:enable Layout/LineLength
        expect(presenter.csv_file_links).to include(
          [
            'Second type CSV',
            [
              :limber_tube_rack,
              :tube_racks_export,
              { format: :csv, id: 'second_csv_id', tube_rack_id: labware.human_barcode }
            ]
          ]
        )
      end
    end
  end
end

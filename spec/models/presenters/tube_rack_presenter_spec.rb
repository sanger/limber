# frozen_string_literal: true

require 'rails_helper'
require 'presenters/plate_presenter'
require_relative 'shared_labware_presenter_examples'

RSpec.describe Presenters::TubeRackPresenter do
  has_a_working_api

  let(:purpose_name) { 'TR96' }
  let(:tube_purpose_name) { 'Tube purpose' }
  let(:title) { "#{purpose_name} : #{tube_purpose_name}" }
  let(:state) { 'pending' }
  let(:summary_tab) { [] }
  let(:sidebar_partial) { 'default' }
  let(:file_links) { [] }

  let(:labware) do
    build :tube_rack, purpose_name: purpose_name, tubes: tubes
  end
  let(:tubes) do
    {
      'A1' => create(:v2_tube, priority: 1, purpose_name: tube_purpose_name),
      'B1' => create(:v2_tube, priority: 3, purpose_name: tube_purpose_name),
      'C1' => create(:v2_tube, priority: 0, purpose_name: tube_purpose_name)
    }
  end

  let(:warnings) { {} }
  let(:label_class) { 'Labels::PlateLabel' }

  before do
    create(:tube_rack_config, uuid: labware.purpose.uuid, warnings: warnings, label_class: label_class, file_links: file_links)
    create(:stock_plate_config, uuid: 'stock-plate-purpose-uuid')
  end

  subject(:presenter) do
    described_class.new(
      api: api,
      labware: labware
    )
  end

  it_behaves_like 'a labware presenter'

  describe '#priority' do
    it 'returns the maximum priority of all tubes' do
      expect(presenter.priority).to eq(3)
    end
  end

  describe '#label' do
    it 'is a Labels::TubeRackLabel' do
      expect(presenter.label).to be_a(Labels::TubeRackLabel)
    end

    it 'has the correct labware' do
      expect(presenter.label.labware).to eq(labware)
    end
  end

  describe '#tube_labels' do
    it 'returns a label for each tube' do
      expect(presenter.tube_labels.length).to eq(3)
    end

    it 'returns tube labels' do
      expect(presenter.tube_labels).to all be_a(Labels::TubeLabel)
    end
  end

  context '#csv_file_links' do
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
        # We'll probably want to adjust the behaviour slightly to grab the information based on the contained tube purposes
        expect(presenter.csv_file_links).to include(['Second type CSV', [:limber_tube_rack, :export, {
                                                      format: :csv,
                                                      id: 'second_csv_id',
                                                      limber_tube_rack_id: labware.human_barcode
                                                    }]])
      end
    end
  end
end

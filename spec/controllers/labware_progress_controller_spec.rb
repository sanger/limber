# frozen_string_literal: true

RSpec.describe LabwareProgressController, type: :controller do
  has_a_working_api

  let(:controller) { described_class.new }

  describe 'GET show' do
    let(:purposes) { create_list :v2_purpose, 2 }
    let(:purpose_names) { purposes.map(&:name) }
    let(:labware) { create_list :labware, 2, purpose: purposes[0] }

    before do
      allow(Settings.pipelines).to receive(:combine_and_order_pipelines).and_return(purpose_names)
      allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware)
    end

    it 'runs ok' do
      get :show, params: { id: 'Heron-384 V2', date: Date.new(2020, 2, 5) }
      expect(response).to have_http_status(:ok)
    end
  end

  describe '#from_date' do
    let(:date) { Date.new(2019, 5, 13) }

    it 'parses the date from the URL parameters' do
      expect(controller.from_date({ date: date })).to eq date
    end

    it 'defaults to a month ago' do
      expect(controller.from_date({})).to eq Time.zone.today.prev_month
    end
  end

  describe '#order_purposes_for_pipelines' do
    let(:pipeline_names) { %w[pipeline1 pipeline2] }

    before do
      allow(Settings.pipelines).to receive(:order_pipeline)
        .with('pipeline1')
        .and_return(%w[pipeline1-purpose1 pipeline1-purpose2])
      allow(Settings.pipelines).to receive(:order_pipeline)
        .with('pipeline2')
        .and_return(%w[pipeline2-purpose1 pipeline2-purpose2])
    end

    it 'orders purposes for given pipelines' do
      result = controller.order_purposes_for_pipelines(pipeline_names)

      expect(result).to eq(
        {
          'pipeline1' => %w[pipeline1-purpose1 pipeline1-purpose2],
          'pipeline2' => %w[pipeline2-purpose1 pipeline2-purpose2]
        }
      )
    end
  end

  describe '#filter_labware_by_related_purpose' do
    # pipelineA has purposeA1 -> purposeA2 -> purposeN3
    # pipelineB has purposeB1 -> purposeB2 -> purposeN3
    # Should labware with purposeN3 be included in pipelineA if it's ancestor is purposeB2?
    let(:labwareA1) { double('Labware', purpose: double('Purpose', name: 'purposeA1'), ancestors: []) }
    let(:labwareA2) { double('Labware', purpose: double('Purpose', name: 'purposeA2'), ancestors: [labwareA1]) }
    let(:labwareB1) { double('Labware', purpose: double('Purpose', name: 'purposeB1'), ancestors: []) }
    let(:labwareB2) { double('Labware', purpose: double('Purpose', name: 'purposeB2'), ancestors: [labwareB1]) }
    let(:labwareN3) { double('Labware', purpose: double('Purpose', name: 'purposeN3'), ancestors: [labwareB2]) }
    let(:labware_records) { [labwareA1, labwareA2, labwareB1, labwareB2, labwareN3] }
    let(:purpose_names_in_pipeline_A) { %w[purposeA1 purposeA2] }
    let(:purpose_names_in_pipeline_B) { %w[purposeB1 purposeB2] }

    it 'includes labware that is part of the given purpose names' do
      result = controller.filter_labware_by_related_purpose(labware_records, purpose_names_in_pipeline_A)
      expect(result).to contain_exactly(labwareA1, labwareA2)
    end

    it 'does not include labware that is not part of the given purpose names or their ancestors' do
      result = controller.filter_labware_by_related_purpose(labware_records, purpose_names_in_pipeline_A)
      expect(result).not_to include(labwareB1, labwareB2, labwareN3)
    end

    it 'includes labware that has an ancestor that is part of the given purpose names' do
      result = controller.filter_labware_by_related_purpose(labware_records, purpose_names_in_pipeline_B)
      expect(result).to contain_exactly(labwareB1, labwareB2, labwareN3)
    end
  end

  describe '#query_labware' do
    let(:page_size) { 2 }
    let(:from_date) { Time.zone.today.prev_month }
    let(:purposes) { ['LTHR Cherrypick', 'LTHR-384 RT'] }
    let(:with_children) { true }
    let(:without_children) { false }
    let(:labware) { create_list :labware, 2 }

    before { allow(Sequencescape::Api::V2).to receive(:merge_page_results).and_return(labware) }

    it 'retrieves labware' do
      result = controller.query_labware(page_size, from_date, purposes, with_children)
      expect(result).to eq labware
    end

    context 'when with_children is true' do
      let(:query) do
        Sequencescape::Api::V2::Labware
          .select(
            { plates: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
            { tubes: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
            { purposes: 'name' }
          )
          .includes(:state_changes, :purpose, 'ancestors.purpose')
          .where(purpose_name: purposes, updated_at_gt: from_date)
          .order(:updated_at)
          .per(page_size)
      end

      before { allow(Sequencescape::Api::V2).to receive(:merge_page_results).with(query).and_return(labware) }

      it 'calls merge_page_results with the correct arguments when with_children is true' do
        result = controller.query_labware(page_size, from_date, purposes, with_children)
        expect(result).to eq labware # labware is only returned if the query is called with the correct arguments
      end
    end

    context 'when with_children is false' do
      let(:query) do
        Sequencescape::Api::V2::Labware
          .select(
            { plates: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
            { tubes: %w[uuid purpose labware_barcode state_changes created_at updated_at ancestors] },
            { purposes: 'name' }
          )
          .includes(:state_changes, :purpose, 'ancestors.purpose')
          .where(purpose_name: purposes, updated_at_gt: from_date, without_children: true)
          .order(:updated_at)
          .per(page_size)
      end

      before { allow(Sequencescape::Api::V2).to receive(:merge_page_results).with(query).and_return(labware) }

      it 'calls merge_page_results with the correct arguments when with_children is false' do
        result = controller.query_labware(page_size, from_date, purposes, without_children)
        expect(result).to eq labware # labware is only returned if the query is called with the correct arguments
      end
    end
  end

  describe '#decide_state' do
    let(:state_change1) { double('StateChange', id: 1, target_state: 'state1') }
    let(:state_change2) { double('StateChange', id: 2, target_state: 'state2') }

    context 'when labware has state changes' do
      let(:labware) { double('Labware', state_changes: [state_change1, state_change2]) }

      it 'decides the state of the labware' do
        result = controller.decide_state(labware)
        expect(result).to eq('state2')
      end
    end

    context 'when labware has no state changes' do
      let(:labware) { double('Labware', state_changes: []) }

      it 'returns "pending"' do
        result = controller.decide_state(labware)
        expect(result).to eq('pending')
      end
    end
  end

  describe '#add_children_metadata' do
    let(:labware1) { create :labware }
    let(:labware2) { create :labware }
    let(:labware_records) { [labware1, labware2] }
    let(:has_children) { true }
    let(:state_suffix) { '_with_children' }

    before { allow(controller).to receive(:decide_state).and_return('pending', 'passed') }

    it 'adds children metadata to labware records' do
      controller.add_children_metadata(labware_records, has_children, state_suffix)

      expect(labware1.has_children).to eq(true)
      expect(labware1.state).to eq('pending')
      expect(labware1.state_with_children).to eq('pending_with_children')

      expect(labware2.has_children).to eq(true)
      expect(labware2.state).to eq('passed')
      expect(labware2.state_with_children).to eq('passed_with_children')
    end
  end

  describe '#query_labware_with_children' do
    let(:page_size) { 10 }
    let(:from_date) { '2022-01-01' }
    let(:purposes) { %w[purpose1 purpose2] }

    let(:labware1) { double('Labware', id: 1) }
    let(:labware2) { double('Labware', id: 2) }
    let(:labware3) { double('Labware', id: 3) }

    before do
      allow(controller).to receive(:query_labware)
        .with(page_size, from_date, purposes, nil)
        .and_return([labware1, labware2, labware3])

      allow(controller).to receive(:query_labware).with(page_size, from_date, purposes, false).and_return([labware1])

      allow(controller).to receive(:add_children_metadata).and_return([labware2, labware3], [labware1])
    end

    it 'queries labware with and without children' do
      result = controller.query_labware_with_children(page_size, from_date, purposes)

      expect(result).to eq([labware1, labware2, labware3])
    end
  end

  describe '#compile_labware_for_purpose' do
    let(:labware1) { double('Labware', state: 'completed') }
    let(:labware2) { double('Labware', state: 'completed') }
    let(:labware3) { double('Labware', state: 'canceled') }
    let(:query_purposes) { %w[purpose1 purpose2] }
    let(:page_size) { 10 }
    let(:from_date) { '2022-01-01' }
    let(:ordered_purposes) { %w[purpose1 purpose2 purpose3] }

    before do
      allow(controller).to receive(:query_labware_with_children)
        .with(page_size, from_date, query_purposes)
        .and_return([labware1, labware2, labware3])

      allow(controller).to receive(:filter_labware_by_related_purpose)
        .with([labware1, labware2], %w[purpose1 purpose2])
        .and_return([labware1, labware2])
    end

    it 'compiles labware for a specific purpose' do
      result = controller.compile_labware_for_purpose(query_purposes, page_size, from_date, ordered_purposes)

      expect(result).to eq([labware1, labware2])
    end
  end
end

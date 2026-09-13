# frozen_string_literal: true

RSpec.describe PipelineVisualiserController do
  let(:controller) { described_class.new }

  describe 'GET show' do
    let(:purpose) { create :purpose }
    let(:labware) { create :labware, purpose: purpose, parents: [], children: [] }
    let(:query) { instance_double(JsonApiClient::Query::Builder) }

    before do
      allow(query).to receive_messages(includes: query, where: query, first: labware)
      allow(Sequencescape::Api::V2::Labware).to receive(:select).and_return(query)
      allow(labware).to receive_messages(parents: [], children: [])
    end

    it 'runs ok' do
      get :show, params: { id: labware.labware_barcode.human }
      expect(response).to have_http_status(:ok)
    end

    context 'when requesting JSON with no barcode' do
      before { get :show, format: :json }

      it 'responds ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns an empty graph' do
        expect(response.parsed_body).to eq('graph_data' => { 'elements' => [] })
      end
    end

    context 'when requesting JSON with a barcode that matches labware' do
      before { get :show, params: { id: labware.labware_barcode.human }, format: :json }

      it 'responds ok' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the graph data for that labware' do
        expect(response.parsed_body).to eq(
          'graph_data' => {
            'elements' => [
              {
                'data' => {
                  'id' => labware.uuid,
                  'label' => "#{labware.labware_barcode.human} (#{purpose.name})",
                  'type' => 'labware',
                  'size' => 96,
                  'barcode' => labware.labware_barcode.human,
                  'purpose' => purpose.name,
                  'state' => 'unknown',
                  'searched' => true
                }
              }
            ]
          }
        )
      end
    end

    context 'when requesting JSON with a barcode that does not match any labware' do
      before do
        allow(query).to receive(:first).and_return(nil)
        get :show, params: { id: 'UNKNOWN-BARCODE' }, format: :json
      end

      it 'responds not found' do
        expect(response).to have_http_status(:not_found)
      end

      it 'returns a not found error' do
        expect(response.parsed_body).to eq('error' => 'Labware not found')
      end
    end
  end

  describe '#labware_to_cytoscape_graph' do
    let(:purpose) { create :purpose }

    def edge_pairs(graph)
      graph[:elements]
        .select { |el| el[:data][:source] }
        .map { |el| [el[:data][:source], el[:data][:target]] }
    end

    def node_ids(graph)
      graph[:elements]
        .reject { |el| el[:data][:source] }
        .map { |el| el[:data][:id] }
    end

    def stub_fetch(controller, all_labware)
      lookup = all_labware.index_by(&:uuid)
      allow(controller).to receive(:retrieve_labware_by_uuid) { |uuid| lookup[uuid] }
    end

    context 'with a simple linear chain' do
      let(:parent) { create :labware, purpose: purpose, parents: [], children: [] }
      let(:child) { create :labware, purpose: purpose, parents: [], children: [] }
      let(:labware) { create :labware, purpose: purpose, parents: [parent], children: [child] }

      before do
        allow(parent).to receive_messages(parents: [], children: [labware])
        allow(child).to receive_messages(children: [], parents: [labware])
        allow(labware).to receive_messages(parents: [parent], children: [child])
        stub_fetch(controller, [parent, labware, child])
      end

      it 'includes all three nodes' do
        graph = controller.send(:labware_to_cytoscape_graph, labware)
        expect(node_ids(graph)).to contain_exactly(parent.uuid, labware.uuid, child.uuid)
      end

      it 'builds correct parent -> child edges' do
        graph = controller.send(:labware_to_cytoscape_graph, labware)
        expect(edge_pairs(graph)).to contain_exactly(
          [parent.uuid, labware.uuid],
          [labware.uuid, child.uuid]
        )
      end
    end

    context 'with a branching structure (two children)' do
      let(:child_a) { create :labware, purpose: purpose, parents: [], children: [] }
      let(:child_b) { create :labware, purpose: purpose, parents: [], children: [] }
      let(:labware) { create :labware, purpose: purpose, parents: [], children: [child_a, child_b] }

      before do
        allow(child_a).to receive_messages(children: [], parents: [labware])
        allow(child_b).to receive_messages(children: [], parents: [labware])
        allow(labware).to receive_messages(parents: [], children: [child_a, child_b])
        stub_fetch(controller, [labware, child_a, child_b])
      end

      it 'includes the searched labware and both children as nodes' do
        graph = controller.send(:labware_to_cytoscape_graph, labware)
        expect(node_ids(graph)).to contain_exactly(labware.uuid, child_a.uuid, child_b.uuid)
      end

      it 'links each child to the searched labware' do
        graph = controller.send(:labware_to_cytoscape_graph, labware)
        expect(edge_pairs(graph)).to contain_exactly(
          [labware.uuid, child_a.uuid],
          [labware.uuid, child_b.uuid]
        )
      end

      it 'does not create a false edge between the two sibling children' do
        graph = controller.send(:labware_to_cytoscape_graph, labware)
        expect(edge_pairs(graph)).not_to include([child_a.uuid, child_b.uuid])
      end
    end
  end
end

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
      allow(controller).to receive(:fetch_with_relatives) { |uuid| lookup[uuid] }
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

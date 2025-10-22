# frozen_string_literal: true

# Stubs:
# Sequencescape::Api::V2::Labware.find_all(
#   { barcode: parent_barcodes },
#   includes: %w[purpose parents parents.purpose]
# )
def stub_labware_find_all_barcode(labwares)
  allow(Sequencescape::Api::V2::Labware).to receive(:find_all).with(
    { barcode: labwares.map(&:barcode) },
    includes: %w[purpose parents parents.purpose]
  ).and_return(labwares)
end

RSpec.describe Presenters::PipelineInfoPresenter do
  before do
    # Ensure the Rails cache is not used during testing to prevent marshal errors
    allow(Rails.cache).to receive(:fetch).and_wrap_original do |_m, *_args, &block|
      block.call
    end
  end

  # Define the presenter and labware for the tests
  let(:presenter) { described_class.new(labware) }
  let(:wgs_purpose) { create(:purpose, uuid: 'wgs-purpose-uuid', name: 'WGS Purpose') }
  let(:labware) { create(:stock_plate, purpose: wgs_purpose) }

  describe '#pipeline_groups' do
    before { Settings.pipelines = PipelineList.new(pipelines_config) }

    context 'when pipelines match by purpose' do
      let(:pipelines_config) do
        {
          'simplest_pipeline' => {
            pipeline_group: 'Group A',
            relationships: {
              'parent' => 'child'
            },
            filters: {}
          },
          'wgs_purpose_pipeline' => {
            pipeline_group: 'Group B',
            relationships: {
              'parent' => 'WGS Purpose'
            },
            filters: {}
          }
        }
      end

      it 'returns the pipeline groups matching the purpose' do
        expect(presenter.pipeline_groups).to eq(['Group B'])
      end
    end

    context 'when no pipelines match' do
      let(:pipelines_config) { {} }

      it 'returns nil' do
        expect(presenter.pipeline_groups).to be_nil
      end
    end

    context 'when pipelines match by library type' do
      let(:request_type) { create(:request_type, key: 'WGS') }
      let(:library_type) { 'WGS' }
      let(:request) do
        [create(:request, :uuid, request_type: request_type, library_type: library_type, state: request_state)]
      end
      let(:aliquot) { [create(:aliquot, request:)] }
      let(:wells) { [create(:well, aliquots: aliquot, location: 'A1')] }
      let(:labware) { create(:plate, purpose: wgs_purpose, wells: wells) }
      let(:pipelines_config) do
        {
          'wgs_purpose_and_unrelated_library_type_pipeline' => {
            pipeline_group: 'Group C',
            relationships: {
              'parent' => 'WGS Purpose'
            },
            filters: {
              'library_type' => 'Unrelated'
            }
          },
          'wgs_purpose_and_library_type_pipeline' => {
            pipeline_group: 'Group D',
            relationships: {
              'parent' => 'WGS Purpose'
            },
            filters: {
              'library_type' => 'WGS'
            }
          }
        }
      end

      context 'with no requests' do
        let(:request) { [] }

        it 'returns both pipeline groups since there is no library type match' do
          expect(presenter.pipeline_groups).to eq(['Group C', 'Group D'])
        end
      end

      context 'with active requests' do
        let(:request_state) { 'pending' }

        it 'returns the pipeline group matching the library type' do
          expect(presenter.pipeline_groups).to eq(['Group D'])
        end
      end

      context 'with completed requests' do
        let(:request_state) { 'completed' }

        it 'returns the pipeline groups matching the library type' do
          expect(presenter.pipeline_groups).to eq(['Group D'])
        end
      end

      context 'with cancelled requests' do
        let(:request_state) { 'cancelled' }

        it 'returns both pipeline groups since there is no library type match' do
          expect(presenter.pipeline_groups).to eq(['Group C', 'Group D'])
        end
      end

      context 'with failed requests' do
        let(:request_state) { 'failed' }

        it 'returns the pipeline groups matching the library type' do
          expect(presenter.pipeline_groups).to eq(['Group D'])
        end
      end
    end

    context 'when the scenario is a linear config' do
      # simple_linear_config: a simple chain of 3 purposes in a row, belonging to the same pipeline group.
      #     All three should return the same pipeline group.
      #
      # chained_linear_config: a chain of 3 purposes in a row, with the first and second having one pipeline group,
      #    and the second and third having another pipeline group.
      #    The first should return the first pipeline group, the second should return both groups?,
      #    and the third should return the second group.

      let(:purpose_first) { create(:purpose, name: 'purpose-first') }
      let(:purpose_middle) { create(:purpose, name: 'purpose-middle') }
      let(:purpose_last) { create(:purpose, name: 'purpose-last') }

      let(:labware_first) { create(:stock_plate, purpose: purpose_first) }
      let(:labware_middle) do
        create(:stock_plate, purpose: purpose_middle, ancestors: [labware_first])
      end
      let(:labware_last) do
        create(
          :stock_plate,
          purpose: purpose_last,
          ancestors: [labware_middle, labware_first]
        )
      end

      context 'when there is a simple linear config' do
        let(:pipelines_config) do
          {
            'simple_linear_config' => {
              pipeline_group: 'Group A',
              relationships: {
                'purpose-first' => 'purpose-middle',
                'purpose-middle' => 'purpose-last'
              },
              filters: {}
            }
          }
        end

        context 'when inspecting the first purpose in the chain' do
          let(:labware) { labware_first }

          it 'returns the correct pipeline group for the first purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end

        context 'when inspecting the middle purpose in the chain' do
          let(:labware) { labware_middle }

          it 'returns the correct pipeline group for the middle purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end

        context 'when inspecting the last purpose in the chain' do
          let(:labware) { labware_last }

          it 'returns the correct pipeline group for the last purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end
      end

      context 'when there is a chained linear config' do
        let(:pipelines_config) do
          {
            'group_a' => {
              pipeline_group: 'Group A',
              relationships: {
                'purpose-first' => 'purpose-middle'
              },
              filters: {}
            },
            'group_b' => {
              pipeline_group: 'Group B',
              relationships: {
                'purpose-middle' => 'purpose-last'
              },
              filters: {}
            }
          }
        end

        context 'when inspecting the first purpose in the chain' do
          let(:labware) { labware_first }

          it 'returns the correct pipeline group for the first purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end

        context 'when inspecting the middle purpose in the chain' do
          let(:labware) { labware_middle }

          it 'returns the correct pipeline group for the middle purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A', 'Group B'])
          end
        end

        context 'when inspecting the last purpose in the chain' do
          let(:labware) { labware_last }

          it 'returns the correct pipeline group for the last purpose' do
            expect(presenter.pipeline_groups).to eq(['Group B'])
          end
        end
      end
    end

    context 'when the scenario is a non-linear config' do
      # branching_config: a common parent with two children, each with their own pipeline group.
      #     The children should return their own pipeline group, but the parent should return both groups?
      #
      # combining_config: a common child with two parents, each with their own pipeline group.
      #     The child should return both groups, but the parents should return their own group.
      #

      let(:purpose_parent) { create(:purpose, name: 'purpose-parent') }
      let(:purpose_child) { create(:purpose, name: 'purpose-child') }
      let(:purpose_other_parent) { create(:purpose, name: 'purpose-other-parent') }
      let(:purpose_other_child) { create(:purpose, name: 'purpose-other-child') }

      let(:labware_branching_parent) { create(:stock_plate, purpose: purpose_parent) }
      let(:labware_child) do
        create(:stock_plate, purpose: purpose_child, ancestors: [labware_parent])
      end
      let(:labware_other_child) do
        create(:stock_plate, purpose: purpose_other_child, ancestors: [labware_parent])
      end

      let(:labware_parent) { create(:stock_plate, purpose: purpose_parent) }
      let(:labware_other_parent) { create(:stock_plate, purpose: purpose_other_parent) }
      let(:labware_combining_child) do
        create(
          :stock_plate,
          purpose: purpose_child,
          ancestors: [labware_parent, labware_other_parent]
        )
      end

      context 'when there is a branching config' do
        let(:pipelines_config) do
          {
            'group_a' => {
              pipeline_group: 'Group A',
              relationships: {
                'purpose-parent' => 'purpose-child'
              },
              filters: {}
            },
            'group_b' => {
              pipeline_group: 'Group B',
              relationships: {
                'purpose-parent' => 'purpose-other-child'
              },
              filters: {}
            }
          }
        end

        context 'when inspecting the common parent purpose in the chain' do
          let(:labware) { labware_branching_parent }

          it 'returns the correct pipeline group for the common parent purpose' do
            expect(presenter.pipeline_groups).to eq(['Group A', 'Group B'])
          end
        end

        context 'when inspecting the first child purpose in the chain' do
          let(:labware) { labware_child }

          it 'returns the correct pipeline group for the first child' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end

        context 'when inspecting the second child purpose in the chain' do
          let(:labware) { labware_other_child }

          it 'returns the correct pipeline group for the second child' do
            expect(presenter.pipeline_groups).to eq(['Group B'])
          end
        end
      end

      context 'when there is a combining config' do
        let(:pipelines_config) do
          {
            'group_a' => {
              pipeline_group: 'Group A',
              relationships: {
                'purpose-parent' => 'purpose-child'
              },
              filters: {}
            },
            'group_b' => {
              pipeline_group: 'Group B',
              relationships: {
                'purpose-other-parent' => 'purpose-child'
              },
              filters: {}
            }
          }
        end

        context 'when inspecting the first parent purpose in the chain' do
          let(:labware) { labware_parent }

          it 'returns the correct pipeline group for the first parent' do
            expect(presenter.pipeline_groups).to eq(['Group A'])
          end
        end

        context 'when inspecting the second parent purpose in the chain' do
          let(:labware) { labware_other_parent }

          it 'returns the correct pipeline group for the second parent' do
            expect(presenter.pipeline_groups).to eq(['Group B'])
          end
        end

        context 'when inspecting the common child purpose in the chain' do
          let(:labware) { labware_combining_child }

          it 'returns the correct pipeline group for the common child' do
            expect(presenter.pipeline_groups).to eq(['Group A', 'Group B'])
          end
        end
      end

      context 'when it is a combining, chained, and branching config' do
        let(:pipelines_config) do
          # purpose-parent    purpose-other-parent
          #       \ A1                  / A2
          #       purpose-combining-child
          #                  | B
          #       purpose-branching-parent
          #        / C1                 \ C2
          # purpose-child         purpose-other-child
          {
            'Group A1 Combined' => {
              pipeline_group: 'Group A1 Combined',
              relationships: {
                'purpose-parent' => 'purpose-combining-child'
              },
              filters: {}
            },
            'Group A2 Combined' => {
              pipeline_group: 'Group A2 Combined',
              relationships: {
                'purpose-other-parent' => 'purpose-combining-child'
              },
              filters: {}
            },
            'Group B Chained' => {
              pipeline_group: 'Group B Chained',
              relationships: {
                'purpose-combining-child' => 'purpose-branching-parent'
              },
              filters: {}
            },
            'Group C1 Branching' => {
              pipeline_group: 'Group C1 Branching',
              relationships: {
                'purpose-branching-parent' => 'purpose-child'
              },
              filters: {}
            },
            'Group C2 Branching' => {
              pipeline_group: 'Group C2 Branching',
              relationships: {
                'purpose-branching-parent' => 'purpose-other-child'
              },
              filters: {}
            }
          }
        end

        let(:purpose_combining_child) { create(:purpose, name: 'purpose-combining-child') }
        let(:purpose_branching_parent) { create(:purpose, name: 'purpose-branching-parent') }

        let(:labware_parent) { create(:stock_plate, purpose: purpose_parent) }
        let(:labware_other_parent) { create(:stock_plate, purpose: purpose_other_parent) }
        let(:labware_combining_child) do
          create(:stock_plate, purpose: purpose_combining_child)
        end
        let(:labware_branching_parent) do
          create(:stock_plate, purpose: purpose_branching_parent)
        end
        let(:labware_child) { create(:stock_plate, purpose: purpose_child) }
        let(:labware_other_child) { create(:stock_plate, purpose: purpose_other_child) }

        before do
          allow(labware_combining_child).to receive_messages(parents: [labware_parent])
          allow(labware_branching_parent).to receive_messages(parents: [labware_combining_child])
          allow(labware_child).to receive_messages(parents: [labware_branching_parent])
          allow(labware_other_child).to receive_messages(parents: [labware_branching_parent])

          stub_labware_find_all_barcode([labware_combining_child])
          stub_labware_find_all_barcode([labware_branching_parent])
          stub_labware_find_all_barcode([labware_parent])
        end

        context 'when inspecting the labware-parent' do
          let(:labware) { labware_parent }

          it 'returns the correct pipeline group for the labware-parent' do
            expect(presenter.pipeline_groups).to eq(['Group A1 Combined'])
          end
        end

        context 'when inspecting the labware-other-parent' do
          let(:labware) { labware_other_parent }

          it 'returns the correct pipeline group for the labware-other-parent' do
            expect(presenter.pipeline_groups).to eq(['Group A2 Combined'])
          end
        end

        context 'when inspecting the labware-combining-child' do
          let(:labware) { labware_combining_child }

          it 'returns the correct pipeline group for the labware-combining-child' do
            expect(presenter.pipeline_groups).to eq(['Group A1 Combined'])
          end
        end

        context 'when inspecting the labware-branching-parent' do
          let(:labware) { labware_branching_parent }

          it 'returns the correct pipeline group for the labware-branching-parent' do
            expect(presenter.pipeline_groups).to eq(['Group B Chained'])
          end
        end

        context 'when inspecting the labware-child' do
          let(:labware) { labware_child }

          it 'returns the correct pipeline group for the labware-child' do
            expect(presenter.pipeline_groups).to eq(['Group C1 Branching'])
          end
        end

        context 'when inspecting the labware-other-child' do
          let(:labware) { labware_other_child }

          it 'returns the correct pipeline group for the labware-other-child' do
            expect(presenter.pipeline_groups).to eq(['Group C2 Branching'])
          end
        end
      end
    end
  end

  describe '#pipeline_group_names' do
    context 'when some pipeline groups are present' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B']) }

      it 'returns the pipeline group names' do
        expect(presenter.pipeline_group_names).to eq('Group A, Group B')
      end
    end

    context 'when many pipeline groups are present' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B', 'Group C', 'Group D']) }

      it 'returns the pipeline group names up to the limit' do
        expect(presenter.pipeline_group_names).to eq('Group A, Group B, Group C, ...(1 more)')
      end
    end

    context 'when no pipeline groups returns an empty array' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(nil) }

      it 'return a short message' do
        expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
      end
    end

    context 'when pipeline groups returns nil' do
      it 'return a short message' do
        expect(presenter.pipeline_group_names).to eq('No Pipelines Found')
      end
    end
  end

  describe '#pipeline_group_name' do
    context 'when there is a single pipeline group' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A']) }

      it 'returns the pipeline group name' do
        expect(presenter.pipeline_group_name).to eq('Group A')
      end
    end

    context 'when there are no pipeline groups' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(nil) }

      it 'returns nil' do
        expect(presenter.pipeline_group_name).to be_nil
      end
    end

    context 'when there are multiple pipeline groups' do
      before { allow(presenter).to receive(:pipeline_groups).and_return(['Group A', 'Group B']) }

      it 'returns nil' do
        expect(presenter.pipeline_group_name).to be_nil
      end
    end
  end

  describe '#grandparent_purposes?' do
    context 'when a tube has no grandparents' do
      before { allow(labware).to receive(:parents).and_return([]) }

      it 'returns false' do
        expect(presenter.grandparent_purposes?).to be false
      end
    end

    context 'when a tube has grandparents' do
      let(:grandparent_purpose) { create(:purpose, name: 'Grandparent Purpose') }
      let(:parent_purpose) { create(:purpose, name: 'Parent Purpose') }

      let(:parent_tube) { create(:stock_tube, purpose: parent_purpose, uuid: 'parent-tube-uuid') }
      let(:grandparent_tube) { create(:stock_tube, purpose: grandparent_purpose, uuid: 'grandparent-tube-uuid') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube])
        allow(parent_tube).to receive_messages(parents: [grandparent_tube])

        stub_labware_find_all_barcode([parent_tube])
        stub_labware_find_all_barcode([grandparent_tube])
      end

      it 'returns true' do
        expect(presenter.grandparent_purposes?).to be true
      end
    end

    context 'when an error occurs during API calls' do
      let(:parent_purpose) { create(:purpose, name: 'Parent Purpose') }

      let(:parent_tube) { create(:stock_tube, purpose: parent_purpose, uuid: 'parent-tube-uuid') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube])
        stub_labware_find_all_barcode([parent_tube])

        allow(Sequencescape::Api::V2::Labware).to receive(:find_all)
          .and_raise(JsonApiClient::Errors::ClientError.new(500, 'Internal Server Error'))
      end

      it 'returns true' do
        expect(presenter.grandparent_purposes?).to be true
      end
    end
  end

  describe '#parent_purposes' do
    context 'when a tube has no parents' do
      before { allow(labware).to receive(:parents).and_return([]) }

      it 'returns an empty string' do
        expect(presenter.parent_purposes).to eq('')
      end
    end

    context 'when a tube has parents' do
      let(:parent_purpose) { create(:purpose, name: 'Parent Purpose') }
      let(:parent_tube) { create(:stock_tube, purpose: parent_purpose, uuid: 'parent-tube-uuid') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube])

        stub_labware_find_all_barcode([parent_tube])
      end

      it 'returns the parent purposes' do
        expect(presenter.parent_purposes).to eq('Parent Purpose')
      end
    end

    context 'when a tube has multiple parents' do
      let(:parent_purpose_1) { create(:purpose, name: 'Parent Purpose 1') }
      let(:parent_purpose_2) { create(:purpose, name: 'Parent Purpose 2') }
      let(:parent_tube_1) { create(:stock_tube, purpose: parent_purpose_1, uuid: 'parent-tube-uuid-1') }
      let(:parent_tube_2) { create(:stock_tube, purpose: parent_purpose_2, uuid: 'parent-tube-uuid-2') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube_1, parent_tube_2])

        stub_labware_find_all_barcode([parent_tube_1, parent_tube_2])
      end

      it 'returns the parent purposes' do
        expect(presenter.parent_purposes).to eq('Parent Purpose 1, Parent Purpose 2')
      end
    end
  end

  describe '#child_purposes' do
    context 'when a tube has no children' do
      before { allow(labware).to receive(:children).and_return([]) }

      it 'returns an empty string' do
        expect(presenter.child_purposes).to eq('')
      end
    end

    context 'when a tube has children' do
      let(:child_purpose_1) { create(:purpose, name: 'Child Purpose 1') }
      let(:child_purpose_2) { create(:purpose, name: 'Child Purpose 2') }

      before { allow(presenter).to receive(:suggested_purposes).and_return([child_purpose_1, child_purpose_2]) }

      it 'returns the child purposes' do
        expect(presenter.child_purposes).to eq('Child Purpose 1, Child Purpose 2')
      end
    end
  end
end

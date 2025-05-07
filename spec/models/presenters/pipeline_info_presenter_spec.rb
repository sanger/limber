# frozen_string_literal: true

def stub_plate_find_all_barcode(plate)
  allow(Sequencescape::Api::V2::Plate).to receive(:find_all).with({ barcode: [plate.barcode] }).and_return([plate])
end

def stub_tube_find_all_barcode(tube)
  allow(Sequencescape::Api::V2::Tube).to receive(:find_all).with({ barcode: [tube.barcode] }).and_return([tube])
end

RSpec.describe Presenters::PipelineInfoPresenter do
  let(:presenter) { described_class.new(labware) }
  let(:wgs_purpose) { create(:v2_purpose, uuid: 'wgs-purpose-uuid', name: 'WGS Purpose') }
  let(:labware) { create(:v2_stock_plate, :has_pooling_metadata, purpose: wgs_purpose) }

  before do
    allow(labware).to receive_messages(
      pooling_metadata: {
        'key1' => {
          'library_type' => {
            'name' => 'WGS'
          }
        }
      },
      ancestors: []
    )
  end

  describe '#pipeline_groups' do
    context 'when pipelines match by purpose' do
      let(:simplest_pipeline) do
        instance_double(Pipeline, pipeline_group: 'Group A', relationships: { 'parent' => 'child' }, filters: {})
      end
      let(:wgs_purpose_pipeline) do
        instance_double(Pipeline, pipeline_group: 'Group B', relationships: { 'parent' => 'WGS Purpose' }, filters: {})
      end

      before { allow(Settings.pipelines).to receive(:list).and_return([simplest_pipeline, wgs_purpose_pipeline]) }

      it 'returns the pipeline groups matching the purpose' do
        expect(presenter.pipeline_groups).to eq(['Group B'])
      end
    end

    context 'when no pipelines match' do
      before { allow(Settings.pipelines).to receive_messages(list: [], select_pipelines_with_purpose: []) }

      it 'returns nil' do
        expect(presenter.pipeline_groups).to be_nil
      end
    end

    context 'when pipelines match by library type' do
      let(:wgs_purpose_and_unrelated_library_type_pipeline) do
        instance_double(
          Pipeline,
          pipeline_group: 'Group C',
          relationships: {
            'parent' => 'WGS Purpose'
          },
          filters: {
            'library_type' => ['Unrelated']
          }
        )
      end
      let(:wgs_purpose_and_library_type_pipeline) do
        instance_double(
          Pipeline,
          pipeline_group: 'Group D',
          relationships: {
            'parent' => 'WGS Purpose'
          },
          filters: {
            'library_type' => ['WGS']
          }
        )
      end

      before do
        pipelines = [wgs_purpose_and_unrelated_library_type_pipeline, wgs_purpose_and_library_type_pipeline]
        allow(Settings.pipelines).to receive_messages(list: pipelines, select: pipelines)
      end

      it 'returns the pipeline groups matching the library type' do
        expect(presenter.pipeline_groups).to eq(['Group D'])
      end
    end

    context 'when the scenario a linear config' do
      # simple_linear_config: a simple chain of 3 purposes in a row, belonging to the same pipeline group.
      #     All three should return the same pipeline group.
      #
      # chained_linear_config: a chain of 3 purposes in a row, with the first and second having one pipeline group,
      #    and the second and third having another pipeline group.
      #    The first should return the first pipeline group, the second should return both groups?,
      #    and the third should return the second group.

      let(:purpose_first) { create(:v2_purpose, name: 'purpose-first') }
      let(:purpose_middle) { create(:v2_purpose, name: 'purpose-middle') }
      let(:purpose_last) { create(:v2_purpose, name: 'purpose-last') }

      let(:labware_first) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_first) }
      let(:labware_middle) do
        create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_middle, ancestors: [labware_first])
      end
      let(:labware_last) do
        create(
          :v2_stock_plate,
          :has_pooling_metadata,
          purpose: purpose_last,
          ancestors: [labware_middle, labware_first]
        )
      end

      context 'when there is a simple linear config' do
        before do
          allow(Settings.pipelines).to receive(:list).and_return(
            [
              instance_double(
                Pipeline,
                pipeline_group: 'Group A',
                relationships: {
                  'purpose-first' => 'purpose-middle',
                  'purpose-middle' => 'purpose-last'
                },
                filters: {
                }
              )
            ]
          )
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
        before do
          allow(Settings.pipelines).to receive(:list).and_return(
            [
              instance_double(
                Pipeline,
                pipeline_group: 'Group A',
                relationships: {
                  'purpose-first' => 'purpose-middle'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group B',
                relationships: {
                  'purpose-middle' => 'purpose-last'
                },
                filters: {
                }
              )
            ]
          )
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

    context 'when the scenario a non-linear config' do
      # branching_config: a common parent with two children, each with their own pipeline group.
      #     The children should return their own pipeline group, but the parent should return both groups?
      #
      # combining_config: a common child with two parents, each with their own pipeline group.
      #     The child should return both groups, but the parents should return their own group.
      #

      let(:purpose_parent) { create(:v2_purpose, name: 'purpose-parent') }
      let(:purpose_child) { create(:v2_purpose, name: 'purpose-child') }
      let(:purpose_other_parent) { create(:v2_purpose, name: 'purpose-other-parent') }
      let(:purpose_other_child) { create(:v2_purpose, name: 'purpose-other-child') }

      let(:labware_branching_parent) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_parent) }
      let(:labware_child) do
        create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_child, ancestors: [labware_parent])
      end
      let(:labware_other_child) do
        create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_other_child, ancestors: [labware_parent])
      end

      let(:labware_parent) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_parent) }
      let(:labware_other_parent) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_other_parent) }
      let(:labware_combining_child) do
        create(
          :v2_stock_plate,
          :has_pooling_metadata,
          purpose: purpose_child,
          ancestors: [labware_parent, labware_other_parent]
        )
      end

      context 'when there is a branching config' do
        before do
          allow(Settings.pipelines).to receive(:list).and_return(
            [
              instance_double(
                Pipeline,
                pipeline_group: 'Group A',
                relationships: {
                  'purpose-parent' => 'purpose-child'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group B',
                relationships: {
                  'purpose-parent' => 'purpose-other-child'
                },
                filters: {
                }
              )
            ]
          )
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
        before do
          allow(Settings.pipelines).to receive(:list).and_return(
            [
              instance_double(
                Pipeline,
                pipeline_group: 'Group A',
                relationships: {
                  'purpose-parent' => 'purpose-combining-child'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group B',
                relationships: {
                  'purpose-other-parent' => 'purpose-combining-child'
                },
                filters: {
                }
              )
            ]
          )
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
            expect(presenter.pipeline_groups).to be_nil
          end
        end
      end

      context 'when it is a combining, chained, and branching config' do
        before do
          allow(Settings.pipelines).to receive(:list).and_return(
            # purpose-parent    purpose-other-parent
            #       \ A1                  / A2
            #       purpose-combining-child
            #                  | B
            #       purpose-branching-parent
            #        / C1                 \ C2
            # purpose-child         purpose-other-child
            [
              instance_double(
                Pipeline,
                pipeline_group: 'Group A1 Combined',
                relationships: {
                  'purpose-parent' => 'purpose-combining-child'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group A2 Combined',
                relationships: {
                  'purpose-other-parent' => 'purpose-combining-child'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group B Chained',
                relationships: {
                  'purpose-combining-child' => 'purpose-branching-parent'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group C1 Branching',
                relationships: {
                  'purpose-branching-parent' => 'purpose-child'
                },
                filters: {
                }
              ),
              instance_double(
                Pipeline,
                pipeline_group: 'Group C2 Branching',
                relationships: {
                  'purpose-branching-parent' => 'purpose-other-child'
                },
                filters: {
                }
              )
            ]
          )

          allow(labware_combining_child).to receive_messages(parents: [labware_parent])
          allow(labware_branching_parent).to receive_messages(parents: [labware_combining_child])
          allow(labware_child).to receive_messages(parents: [labware_branching_parent])
          allow(labware_other_child).to receive_messages(parents: [labware_branching_parent])

          stub_plate_find_all_barcode(labware_combining_child)
          stub_plate_find_all_barcode(labware_branching_parent)
          stub_plate_find_all_barcode(labware_parent)
        end

        let(:purpose_combining_child) { create(:v2_purpose, name: 'purpose-combining-child') }
        let(:purpose_branching_parent) { create(:v2_purpose, name: 'purpose-branching-parent') }

        let(:labware_parent) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_parent) }
        let(:labware_other_parent) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_other_parent) }
        let(:labware_combining_child) do
          create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_combining_child)
        end
        let(:labware_branching_parent) do
          create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_branching_parent)
        end
        let(:labware_child) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_child) }
        let(:labware_other_child) { create(:v2_stock_plate, :has_pooling_metadata, purpose: purpose_other_child) }

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

  describe '#grandparent_purposes' do
    context 'when a tube has no grandparents' do
      before { allow(labware).to receive(:parents).and_return([]) }

      it 'returns an empty string' do
        expect(presenter.grandparent_purposes).to eq('')
      end
    end

    context 'when a tube has grandparents' do
      let(:grandparent_purpose) { create(:v2_purpose, name: 'Grandparent Purpose') }
      let(:parent_purpose) { create(:v2_purpose, name: 'Parent Purpose') }

      let(:parent_tube) { create(:v2_stock_tube, purpose: parent_purpose, uuid: 'parent-tube-uuid') }
      let(:grandparent_tube) { create(:v2_stock_tube, purpose: grandparent_purpose, uuid: 'grandparent-tube-uuid') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube])
        allow(parent_tube).to receive_messages(parents: [grandparent_tube])

        stub_tube_find_all_barcode(parent_tube)
      end

      it 'returns the grandparent purposes' do
        expect(presenter.grandparent_purposes).to eq('Grandparent Purpose')
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
      let(:parent_purpose) { create(:v2_purpose, name: 'Parent Purpose') }
      let(:parent_tube) { create(:v2_stock_tube, purpose: parent_purpose, uuid: 'parent-tube-uuid') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube])

        stub_tube_find_all_barcode(parent_tube)
      end

      it 'returns the parent purposes' do
        expect(presenter.parent_purposes).to eq('Parent Purpose')
      end
    end

    context 'when a tube has multiple parents' do
      let(:parent_purpose_1) { create(:v2_purpose, name: 'Parent Purpose 1') }
      let(:parent_purpose_2) { create(:v2_purpose, name: 'Parent Purpose 2') }
      let(:parent_tube_1) { create(:v2_stock_tube, purpose: parent_purpose_1, uuid: 'parent-tube-uuid-1') }
      let(:parent_tube_2) { create(:v2_stock_tube, purpose: parent_purpose_2, uuid: 'parent-tube-uuid-2') }

      before do
        allow(labware).to receive_messages(parents: [parent_tube_1, parent_tube_2])

        stub_tube_find_all_barcode(parent_tube_1)
        stub_tube_find_all_barcode(parent_tube_2)
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
      let(:child_purpose_1) { create(:v2_purpose, name: 'Child Purpose 1') }
      let(:child_purpose_2) { create(:v2_purpose, name: 'Child Purpose 2') }

      before { allow(presenter).to receive(:suggested_purposes).and_return([child_purpose_1, child_purpose_2]) }

      it 'returns the child purposes' do
        expect(presenter.child_purposes).to eq('Child Purpose 1, Child Purpose 2')
      end
    end
  end
end

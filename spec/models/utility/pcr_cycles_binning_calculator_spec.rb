# frozen_string_literal: true

require 'spec_helper'
require 'support/shared_examples/common_calculations_shared_examples'

RSpec.describe Utility::PcrCyclesBinningCalculator do
  context 'when computing values for pcr cycles binning' do
    subject { described_class.new(well_details) }

    let(:parent_uuid) { 'example-plate-uuid' }
    let(:plate_size) { 96 }

    let(:well_a1) { create(:well, position: { 'name' => 'A1' }, requests_as_source: [requests[0]]) }
    let(:well_b1) { create(:well, position: { 'name' => 'B1' }, requests_as_source: [requests[1]]) }
    let(:well_c1) { create(:well, position: { 'name' => 'C1' }, requests_as_source: [requests[2]]) }
    let(:well_d1) { create(:well, position: { 'name' => 'D1' }, requests_as_source: [requests[3]]) }

    let(:parent_plate) do
      create :plate,
             uuid: parent_uuid,
             barcode_number: '2',
             size: plate_size,
             wells: [well_a1, well_b1, well_c1, well_d1],
             outer_requests: requests
    end

    let(:library_type_name) { 'Test Library Type' }

    let(:requests) do
      Array.new(4) do |i|
        create :library_request, state: 'pending', uuid: "request-#{i}", library_type: library_type_name
      end
    end

    let(:well_details) do
      {
        'A1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'B1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'D1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 2,
          'coverage' => 15
        },
        'E1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 30
        },
        'F1' => {
          'sample_volume' => 4.0,
          'diluent_volume' => 26.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'H1' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 2,
          'coverage' => 30
        },
        'A2' => {
          'sample_volume' => 3.2,
          'diluent_volume' => 26.8,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'B2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 2,
          'coverage' => 15
        },
        'C2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 2,
          'coverage' => 15
        },
        'D2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 12,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'E2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        },
        'F2' => {
          'sample_volume' => 30.0,
          'diluent_volume' => 0.0,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => 'N',
          'sub_pool' => nil,
          'coverage' => nil
        },
        'G2' => {
          'sample_volume' => 5.0,
          'diluent_volume' => 25.0,
          'pcr_cycles' => 14,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 30
        },
        'H2' => {
          'sample_volume' => 3.621,
          'diluent_volume' => 27.353,
          'pcr_cycles' => 16,
          'submit_for_sequencing' => 'Y',
          'sub_pool' => 1,
          'coverage' => 15
        }
      }
    end

    describe '#compute_well_transfers' do
      context 'for a simple example with few wells' do
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A2',
              'volume' => '5.0'
            },
            'B1' => {
              'dest_locn' => 'B2',
              'volume' => '5.0'
            },
            'D1' => {
              'dest_locn' => 'A1',
              'volume' => '5.0'
            },
            'E1' => {
              'dest_locn' => 'A3',
              'volume' => '5.0'
            },
            'F1' => {
              'dest_locn' => 'B3',
              'volume' => '4.0'
            },
            'H1' => {
              'dest_locn' => 'C3',
              'volume' => '5.0'
            },
            'A2' => {
              'dest_locn' => 'D3',
              'volume' => '3.2'
            },
            'B2' => {
              'dest_locn' => 'E3',
              'volume' => '5.0'
            },
            'C2' => {
              'dest_locn' => 'F3',
              'volume' => '5.0'
            },
            'D2' => {
              'dest_locn' => 'G3',
              'volume' => '5.0'
            },
            'E2' => {
              'dest_locn' => 'C2',
              'volume' => '5.0'
            },
            'F2' => {
              'dest_locn' => 'B1',
              'volume' => '30.0'
            },
            'G2' => {
              'dest_locn' => 'D2',
              'volume' => '5.0'
            },
            'H2' => {
              'dest_locn' => 'C1',
              'volume' => '3.621'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
        end
      end

      context 'when all wells fall in the same bin' do
        let(:well_details) do
          {
            'A1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'E1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'F1' => {
              'sample_volume' => 4.0,
              'diluent_volume' => 26.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'A2' => {
              'sample_volume' => 3.2,
              'diluent_volume' => 26.8,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'C2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'D2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F2' => {
              'sample_volume' => 30.0,
              'diluent_volume' => 0.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'N',
              'sub_pool' => nil,
              'coverage' => nil
            },
            'G2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'H2' => {
              'sample_volume' => 3.621,
              'diluent_volume' => 27.353,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            }
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'volume' => '5.0'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'volume' => '5.0'
            },
            'D1' => {
              'dest_locn' => 'C1',
              'volume' => '5.0'
            },
            'E1' => {
              'dest_locn' => 'D1',
              'volume' => '5.0'
            },
            'F1' => {
              'dest_locn' => 'E1',
              'volume' => '4.0'
            },
            'H1' => {
              'dest_locn' => 'F1',
              'volume' => '5.0'
            },
            'A2' => {
              'dest_locn' => 'G1',
              'volume' => '3.2'
            },
            'B2' => {
              'dest_locn' => 'H1',
              'volume' => '5.0'
            },
            'C2' => {
              'dest_locn' => 'A2',
              'volume' => '5.0'
            },
            'D2' => {
              'dest_locn' => 'B2',
              'volume' => '5.0'
            },
            'E2' => {
              'dest_locn' => 'C2',
              'volume' => '5.0'
            },
            'F2' => {
              'dest_locn' => 'D2',
              'volume' => '30.0'
            },
            'G2' => {
              'dest_locn' => 'E2',
              'volume' => '5.0'
            },
            'H2' => {
              'dest_locn' => 'F2',
              'volume' => '3.621'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
        end
      end

      context 'when bins span complete columns' do
        let(:well_details) do
          {
            'A1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'E1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'F1' => {
              'sample_volume' => 4.0,
              'diluent_volume' => 26.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'H1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'A2' => {
              'sample_volume' => 3.2,
              'diluent_volume' => 26.8,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'C2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'D2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F2' => {
              'sample_volume' => 30.0,
              'diluent_volume' => 0.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'N',
              'sub_pool' => nil,
              'coverage' => nil
            },
            'G2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'H2' => {
              'sample_volume' => 3.621,
              'diluent_volume' => 27.353,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            }
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'volume' => '5.0'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'volume' => '5.0'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'volume' => '5.0'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'volume' => '5.0'
            },
            'E1' => {
              'dest_locn' => 'E1',
              'volume' => '5.0'
            },
            'F1' => {
              'dest_locn' => 'F1',
              'volume' => '4.0'
            },
            'G1' => {
              'dest_locn' => 'G1',
              'volume' => '5.0'
            },
            'H1' => {
              'dest_locn' => 'H1',
              'volume' => '5.0'
            },
            'A2' => {
              'dest_locn' => 'A2',
              'volume' => '3.2'
            },
            'B2' => {
              'dest_locn' => 'B2',
              'volume' => '5.0'
            },
            'C2' => {
              'dest_locn' => 'C2',
              'volume' => '5.0'
            },
            'D2' => {
              'dest_locn' => 'D2',
              'volume' => '5.0'
            },
            'E2' => {
              'dest_locn' => 'E2',
              'volume' => '5.0'
            },
            'F2' => {
              'dest_locn' => 'F2',
              'volume' => '30.0'
            },
            'G2' => {
              'dest_locn' => 'G2',
              'volume' => '5.0'
            },
            'H2' => {
              'dest_locn' => 'H2',
              'volume' => '3.621'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
        end
      end

      context 'when requiring compression due to numbers of wells' do
        let(:well_details) do
          {
            'A1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'E1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'F1' => {
              'sample_volume' => 4.0,
              'diluent_volume' => 26.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'H1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'A2' => {
              'sample_volume' => 3.2,
              'diluent_volume' => 26.8,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'C2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'D2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F2' => {
              'sample_volume' => 30.0,
              'diluent_volume' => 0.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'N',
              'sub_pool' => nil,
              'coverage' => nil
            },
            'G2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'H2' => {
              'sample_volume' => 3.621,
              'diluent_volume' => 27.353,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H3' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H4' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H5' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H6' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H7' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H8' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H9' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H10' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H11' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'A12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'H12' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            }
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'A1',
              'volume' => '5.0'
            },
            'B1' => {
              'dest_locn' => 'B1',
              'volume' => '5.0'
            },
            'C1' => {
              'dest_locn' => 'C1',
              'volume' => '5.0'
            },
            'D1' => {
              'dest_locn' => 'D1',
              'volume' => '5.0'
            },
            'E1' => {
              'dest_locn' => 'E1',
              'volume' => '5.0'
            },
            'F1' => {
              'dest_locn' => 'F1',
              'volume' => '4.0'
            },
            'G1' => {
              'dest_locn' => 'G1',
              'volume' => '5.0'
            },
            'H1' => {
              'dest_locn' => 'H1',
              'volume' => '5.0'
            },
            'A2' => {
              'dest_locn' => 'A2',
              'volume' => '3.2'
            },
            'B2' => {
              'dest_locn' => 'B2',
              'volume' => '5.0'
            },
            'C2' => {
              'dest_locn' => 'C2',
              'volume' => '5.0'
            },
            'D2' => {
              'dest_locn' => 'D2',
              'volume' => '5.0'
            },
            'E2' => {
              'dest_locn' => 'E2',
              'volume' => '5.0'
            },
            'F2' => {
              'dest_locn' => 'F2',
              'volume' => '30.0'
            },
            'G2' => {
              'dest_locn' => 'G2',
              'volume' => '5.0'
            },
            'H2' => {
              'dest_locn' => 'H2',
              'volume' => '3.621'
            },
            'A3' => {
              'dest_locn' => 'A3',
              'volume' => '5.0'
            },
            'B3' => {
              'dest_locn' => 'B3',
              'volume' => '5.0'
            },
            'C3' => {
              'dest_locn' => 'C3',
              'volume' => '5.0'
            },
            'D3' => {
              'dest_locn' => 'D3',
              'volume' => '5.0'
            },
            'E3' => {
              'dest_locn' => 'E3',
              'volume' => '5.0'
            },
            'F3' => {
              'dest_locn' => 'F3',
              'volume' => '5.0'
            },
            'G3' => {
              'dest_locn' => 'G3',
              'volume' => '5.0'
            },
            'H3' => {
              'dest_locn' => 'H3',
              'volume' => '5.0'
            },
            'A4' => {
              'dest_locn' => 'A4',
              'volume' => '5.0'
            },
            'B4' => {
              'dest_locn' => 'B4',
              'volume' => '5.0'
            },
            'C4' => {
              'dest_locn' => 'C4',
              'volume' => '5.0'
            },
            'D4' => {
              'dest_locn' => 'D4',
              'volume' => '5.0'
            },
            'E4' => {
              'dest_locn' => 'E4',
              'volume' => '5.0'
            },
            'F4' => {
              'dest_locn' => 'F4',
              'volume' => '5.0'
            },
            'G4' => {
              'dest_locn' => 'G4',
              'volume' => '5.0'
            },
            'H4' => {
              'dest_locn' => 'H4',
              'volume' => '5.0'
            },
            'A5' => {
              'dest_locn' => 'A5',
              'volume' => '5.0'
            },
            'B5' => {
              'dest_locn' => 'B5',
              'volume' => '5.0'
            },
            'C5' => {
              'dest_locn' => 'C5',
              'volume' => '5.0'
            },
            'D5' => {
              'dest_locn' => 'D5',
              'volume' => '5.0'
            },
            'E5' => {
              'dest_locn' => 'E5',
              'volume' => '5.0'
            },
            'F5' => {
              'dest_locn' => 'F5',
              'volume' => '5.0'
            },
            'G5' => {
              'dest_locn' => 'G5',
              'volume' => '5.0'
            },
            'H5' => {
              'dest_locn' => 'H5',
              'volume' => '5.0'
            },
            'A6' => {
              'dest_locn' => 'A6',
              'volume' => '5.0'
            },
            'B6' => {
              'dest_locn' => 'B6',
              'volume' => '5.0'
            },
            'C6' => {
              'dest_locn' => 'C6',
              'volume' => '5.0'
            },
            'D6' => {
              'dest_locn' => 'D6',
              'volume' => '5.0'
            },
            'E6' => {
              'dest_locn' => 'E6',
              'volume' => '5.0'
            },
            'F6' => {
              'dest_locn' => 'F6',
              'volume' => '5.0'
            },
            'G6' => {
              'dest_locn' => 'G6',
              'volume' => '5.0'
            },
            'H6' => {
              'dest_locn' => 'H6',
              'volume' => '5.0'
            },
            'A7' => {
              'dest_locn' => 'A7',
              'volume' => '5.0'
            },
            'B7' => {
              'dest_locn' => 'B7',
              'volume' => '5.0'
            },
            'C7' => {
              'dest_locn' => 'C7',
              'volume' => '5.0'
            },
            'D7' => {
              'dest_locn' => 'D7',
              'volume' => '5.0'
            },
            'E7' => {
              'dest_locn' => 'E7',
              'volume' => '5.0'
            },
            'F7' => {
              'dest_locn' => 'F7',
              'volume' => '5.0'
            },
            'G7' => {
              'dest_locn' => 'G7',
              'volume' => '5.0'
            },
            'H7' => {
              'dest_locn' => 'H7',
              'volume' => '5.0'
            },
            'A8' => {
              'dest_locn' => 'A8',
              'volume' => '5.0'
            },
            'B8' => {
              'dest_locn' => 'B8',
              'volume' => '5.0'
            },
            'C8' => {
              'dest_locn' => 'C8',
              'volume' => '5.0'
            },
            'D8' => {
              'dest_locn' => 'D8',
              'volume' => '5.0'
            },
            'E8' => {
              'dest_locn' => 'E8',
              'volume' => '5.0'
            },
            'F8' => {
              'dest_locn' => 'F8',
              'volume' => '5.0'
            },
            'G8' => {
              'dest_locn' => 'G8',
              'volume' => '5.0'
            },
            'H8' => {
              'dest_locn' => 'H8',
              'volume' => '5.0'
            },
            'A9' => {
              'dest_locn' => 'A9',
              'volume' => '5.0'
            },
            'B9' => {
              'dest_locn' => 'B9',
              'volume' => '5.0'
            },
            'C9' => {
              'dest_locn' => 'C9',
              'volume' => '5.0'
            },
            'D9' => {
              'dest_locn' => 'D9',
              'volume' => '5.0'
            },
            'E9' => {
              'dest_locn' => 'E9',
              'volume' => '5.0'
            },
            'F9' => {
              'dest_locn' => 'F9',
              'volume' => '5.0'
            },
            'G9' => {
              'dest_locn' => 'G9',
              'volume' => '5.0'
            },
            'H9' => {
              'dest_locn' => 'H9',
              'volume' => '5.0'
            },
            'A10' => {
              'dest_locn' => 'A10',
              'volume' => '5.0'
            },
            'B10' => {
              'dest_locn' => 'B10',
              'volume' => '5.0'
            },
            'C10' => {
              'dest_locn' => 'C10',
              'volume' => '5.0'
            },
            'D10' => {
              'dest_locn' => 'D10',
              'volume' => '5.0'
            },
            'E10' => {
              'dest_locn' => 'E10',
              'volume' => '5.0'
            },
            'F10' => {
              'dest_locn' => 'F10',
              'volume' => '5.0'
            },
            'G10' => {
              'dest_locn' => 'G10',
              'volume' => '5.0'
            },
            'H10' => {
              'dest_locn' => 'H10',
              'volume' => '5.0'
            },
            'A11' => {
              'dest_locn' => 'A11',
              'volume' => '5.0'
            },
            'B11' => {
              'dest_locn' => 'B11',
              'volume' => '5.0'
            },
            'C11' => {
              'dest_locn' => 'C11',
              'volume' => '5.0'
            },
            'D11' => {
              'dest_locn' => 'D11',
              'volume' => '5.0'
            },
            'E11' => {
              'dest_locn' => 'E11',
              'volume' => '5.0'
            },
            'F11' => {
              'dest_locn' => 'F11',
              'volume' => '5.0'
            },
            'G11' => {
              'dest_locn' => 'G11',
              'volume' => '5.0'
            },
            'H11' => {
              'dest_locn' => 'H11',
              'volume' => '5.0'
            },
            'A12' => {
              'dest_locn' => 'A12',
              'volume' => '5.0'
            },
            'B12' => {
              'dest_locn' => 'B12',
              'volume' => '5.0'
            },
            'C12' => {
              'dest_locn' => 'C12',
              'volume' => '5.0'
            },
            'D12' => {
              'dest_locn' => 'D12',
              'volume' => '5.0'
            },
            'E12' => {
              'dest_locn' => 'E12',
              'volume' => '5.0'
            },
            'F12' => {
              'dest_locn' => 'F12',
              'volume' => '5.0'
            },
            'G12' => {
              'dest_locn' => 'G12',
              'volume' => '5.0'
            },
            'H12' => {
              'dest_locn' => 'H12',
              'volume' => '5.0'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
        end
      end

      context 'when requiring compression due to large number of bins' do
        let(:well_details) do
          {
            'A1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 5,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 6,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'C1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 7,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'D1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 8,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'E1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 9,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'F1' => {
              'sample_volume' => 4.0,
              'diluent_volume' => 26.0,
              'pcr_cycles' => 10,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'G1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 11,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'H1' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 12,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 30
            },
            'A2' => {
              'sample_volume' => 3.2,
              'diluent_volume' => 26.8,
              'pcr_cycles' => 13,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'B2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 14,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'C2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 15,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 2,
              'coverage' => 15
            },
            'D2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 16,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'E2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 17,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            },
            'F2' => {
              'sample_volume' => 30.0,
              'diluent_volume' => 0.0,
              'pcr_cycles' => 18,
              'submit_for_sequencing' => 'N',
              'sub_pool' => nil,
              'coverage' => nil
            },
            'G2' => {
              'sample_volume' => 5.0,
              'diluent_volume' => 25.0,
              'pcr_cycles' => 19,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 30
            },
            'H2' => {
              'sample_volume' => 3.621,
              'diluent_volume' => 27.353,
              'pcr_cycles' => 20,
              'submit_for_sequencing' => 'Y',
              'sub_pool' => 1,
              'coverage' => 15
            }
          }
        end
        let(:expd_transfers) do
          {
            'A1' => {
              'dest_locn' => 'H2',
              'volume' => '5.0'
            },
            'B1' => {
              'dest_locn' => 'G2',
              'volume' => '5.0'
            },
            'C1' => {
              'dest_locn' => 'F2',
              'volume' => '5.0'
            },
            'D1' => {
              'dest_locn' => 'E2',
              'volume' => '5.0'
            },
            'E1' => {
              'dest_locn' => 'D2',
              'volume' => '5.0'
            },
            'F1' => {
              'dest_locn' => 'C2',
              'volume' => '4.0'
            },
            'G1' => {
              'dest_locn' => 'B2',
              'volume' => '5.0'
            },
            'H1' => {
              'dest_locn' => 'A2',
              'volume' => '5.0'
            },
            'A2' => {
              'dest_locn' => 'H1',
              'volume' => '3.2'
            },
            'B2' => {
              'dest_locn' => 'G1',
              'volume' => '5.0'
            },
            'C2' => {
              'dest_locn' => 'F1',
              'volume' => '5.0'
            },
            'D2' => {
              'dest_locn' => 'E1',
              'volume' => '5.0'
            },
            'E2' => {
              'dest_locn' => 'D1',
              'volume' => '5.0'
            },
            'F2' => {
              'dest_locn' => 'C1',
              'volume' => '30.0'
            },
            'G2' => {
              'dest_locn' => 'B1',
              'volume' => '5.0'
            },
            'H2' => {
              'dest_locn' => 'A1',
              'volume' => '3.621'
            }
          }
        end

        it 'creates the correct transfers' do
          expect(subject.compute_well_transfers(parent_plate)).to eq(expd_transfers)
        end
      end
    end

    # describe '#compute_presenter_bin_details' do
    #   context 'when generating presenter well bin details' do

    #     it 'creates the correct well information' do
    #       expect(subject.compute_presenter_bin_details(child_plate)).to eq(expected_bin_details)
    #     end
    #   end
    # end
  end
end

RSpec.describe Utility::CommonDilutionCalculations::Binner do
  context 'when calculating binned well locations' do
    it_behaves_like 'it throws exceptions from binner class'
  end
end

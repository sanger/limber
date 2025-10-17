# frozen_string_literal: true

require 'rails_helper'

class TestPoolingClass
  include LabwareCreators::DonorPoolingCalculator
end

RSpec.describe LabwareCreators::DonorPoolingCalculator do
  let(:instance_of_test_pooling_class) { TestPoolingClass.new }
  let(:pool) { [source_well1] }
  let(:source_well1) { create :well, aliquots: [aliquot1] }
  let(:aliquot1) { create :aliquot, request: request1 }
  let(:request1) { create :scrna_customer_request, request_metadata: request_metadata1 }
  let(:request_metadata1) { create :request_metadata, cells_per_chip_well:, allowance_band: }
  let(:cells_per_chip_well) { 48_750 }
  let(:allowance_band) { '2 pool attempts, 2 counts' }

  describe '#number_of_cells_per_chip_well_from_request' do
    context 'when the request metadata is nil' do
      let(:request_metadata1) { nil }

      it 'returns nil' do
        expect do
          instance_of_test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)
        end.to raise_error StandardError,
                           'No request found for source well at A1, cannot fetch ' \
                           'cells per chip well metadata for allowance band calculations'
      end
    end

    context 'when there is a single source well with request_metadata' do
      it 'returns the number of cells per chip well' do
        expect(instance_of_test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(
          cells_per_chip_well
        )
      end
    end

    context 'when there are multiple source wells' do
      let(:source_well2) { create :well, aliquots: [aliquot2] }
      let(:aliquot2) { create :aliquot, request: request2 }
      let(:request2) { create :scrna_customer_request, request_metadata: request_metadata2 }
      let(:request_metadata2) { create :request_metadata, cells_per_chip_well: }
      let(:pool) { [source_well1, source_well2] }

      it 'returns the number of cells per chip well from the first source well' do
        expect(instance_of_test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(
          cells_per_chip_well
        )
      end
    end

    context 'when there are multiple aliquots in a source well' do
      it 'returns the number of cells per chip well from the first aliquot' do
        expect(instance_of_test_pooling_class.send(:number_of_cells_per_chip_well_from_request, pool)).to eq(
          cells_per_chip_well
        )
      end
    end
  end

  describe '#allowance_band_from_request' do
    context 'when the request metadata is nil' do
      let(:request_metadata1) { nil }

      it 'returns nil' do
        expect do
          instance_of_test_pooling_class.send(:allowance_band_from_request, pool)
        end.to raise_error StandardError,
                           'No request found for source well at A1, cannot fetch ' \
                           'allowance band well metadata for allowance band calculations'
      end
    end

    context 'when there is a single source well with request_metadata' do
      it 'returns the allowance band' do
        expect(instance_of_test_pooling_class.send(:allowance_band_from_request, pool)).to eq(allowance_band)
      end
    end

    context 'when there are multiple source wells' do
      let(:source_well2) { create :well, aliquots: [aliquot2] }
      let(:aliquot2) { create :aliquot, request: request2 }
      let(:request2) { create :scrna_customer_request, request_metadata: request_metadata2 }
      let(:request_metadata2) { create :request_metadata, allowance_band: }
      let(:pool) { [source_well1, source_well2] }

      it 'returns the allowance band from the first source well' do
        expect(instance_of_test_pooling_class.send(:allowance_band_from_request, pool)).to eq(allowance_band)
      end
    end

    context 'when there are multiple aliquots in a source well' do
      it 'returns the allowance_band from the first aliquot' do
        expect(instance_of_test_pooling_class.send(:allowance_band_from_request, pool)).to eq(allowance_band)
      end
    end
  end

  describe '#calculate_total_cells_in_300ul' do
    let(:count_of_samples_in_pool) { 10 }
    let(:num_cells_per_sample) { Rails.application.config.scrna_config[:required_number_of_cells_per_sample_in_pool] }
    let(:wastage_factor) { Rails.application.config.scrna_config[:wastage_factor] }
    let(:expected_volume) do
      (count_of_samples_in_pool * num_cells_per_sample) * wastage_factor.call(count_of_samples_in_pool)
    end

    it 'calculates the value correctly' do
      expect(described_class.calculate_total_cells_in_300ul(count_of_samples_in_pool)).to eq(
        expected_volume
      )
    end

    it 'calculates the value correctly when the wastage_factor is above 13' do
      count_of_samples_in_pool = 15
      expected_volume = count_of_samples_in_pool * num_cells_per_sample * wastage_factor.call(count_of_samples_in_pool)

      expect(described_class.calculate_total_cells_in_300ul(count_of_samples_in_pool)).to eq(
        expected_volume
      )
    end
  end

  describe '#calculate_chip_loading_volume' do
    context 'when the number of cells per chip well is present' do
      let(:expected_volume) do
        cells_per_chip_well / Rails.application.config.scrna_config[:desired_chip_loading_concentration]
      end

      it 'calculates the chip loading volume' do
        expect(instance_of_test_pooling_class.send(:calculate_chip_loading_volume, cells_per_chip_well)).to eq(
          expected_volume
        )
      end
    end
  end

  describe '#calculate_allowance' do
    let(:chip_loading_volume) { 50.0 }

    context 'when allowance_band is "2 pool attempts, 2 counts"' do
      let(:expected_volume) do
        (chip_loading_volume * 2) + (2 * Rails.application.config.scrna_config[:volume_taken_for_cell_counting]) +
          Rails.application.config.scrna_config[:wastage_volume]
      end

      it 'calculates the allowance band volume' do
        allowance_band = '2 pool attempts, 2 counts'
        expect(instance_of_test_pooling_class.send(:calculate_allowance, chip_loading_volume, allowance_band)).to eq(
          expected_volume
        )
      end
    end

    context 'when allowance_band is "2 pool attempts, 1 count"' do
      let(:expected_volume) do
        (chip_loading_volume * 2) + Rails.application.config.scrna_config[:volume_taken_for_cell_counting] +
          Rails.application.config.scrna_config[:wastage_volume]
      end

      it 'calculates the allowance band volume' do
        allowance_band = '2 pool attempts, 1 count'
        expect(instance_of_test_pooling_class.send(:calculate_allowance, chip_loading_volume, allowance_band)).to eq(
          expected_volume
        )
      end
    end

    context 'when allowance_band is "1 pool attempt, 2 counts"' do
      let(:expected_volume) do
        chip_loading_volume + (2 * Rails.application.config.scrna_config[:volume_taken_for_cell_counting]) +
          Rails.application.config.scrna_config[:wastage_volume]
      end

      it 'calculates the allowance band volume' do
        allowance_band = '1 pool attempt, 2 counts'
        expect(instance_of_test_pooling_class.send(:calculate_allowance, chip_loading_volume, allowance_band)).to eq(
          expected_volume
        )
      end
    end

    context 'when allowance_band is "1 pool attempt, 1 count"' do
      let(:expected_volume) do
        chip_loading_volume + Rails.application.config.scrna_config[:volume_taken_for_cell_counting] +
          Rails.application.config.scrna_config[:wastage_volume]
      end

      it 'calculates the allowance band volume' do
        allowance_band = '1 pool attempt, 1 count'
        expect(instance_of_test_pooling_class.send(:calculate_allowance, chip_loading_volume, allowance_band)).to eq(
          expected_volume
        )
      end
    end
  end

  describe '#check_pool_for_allowance_band' do
    # 2nd source well
    let(:source_well2) { create :well, aliquots: [aliquot2] }
    let(:aliquot2) { create :aliquot, request: request2 }
    let(:request2) { create :scrna_customer_request, request_metadata: request_metadata2 }
    let(:request_metadata2) { create :request_metadata, cells_per_chip_well:, allowance_band: }

    # pool with 2 source wells
    let(:pool) { [source_well1, source_well2] }

    # destination plate and well
    let(:dest_plate) { create :plate, wells: [dest_well] }
    let(:dest_well) { create :well, uuid: 'dest_well_uuid', location: 'A1' }
    let(:dest_well_location) { dest_well.location }

    context 'when the count of samples in pool is outside the range covered in the allowance table' do
      it 'stores the number of cells per chip well taken from the request on the destination well' do
        expect(instance_of_test_pooling_class).to receive(:create_new_well_metadata).with(
          Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key],
          cells_per_chip_well,
          dest_well
        )

        instance_of_test_pooling_class.check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
      end
    end

    context 'when the count of samples in pool is within the range covered in the allowance table' do
      # 3rd source well
      let(:source_well3) { create :well, aliquots: [aliquot3] }
      let(:aliquot3) { create :aliquot, request: request3 }
      let(:request3) { create :scrna_customer_request, request_metadata: request_metadata3 }
      let(:request_metadata3) { create :request_metadata, cells_per_chip_well:, allowance_band: }

      # 4th source well
      let(:source_well4) { create :well, aliquots: [aliquot4] }
      let(:aliquot4) { create :aliquot, request: request4 }
      let(:request4) { create :scrna_customer_request, request_metadata: request_metadata4 }
      let(:request_metadata4) { create :request_metadata, cells_per_chip_well:, allowance_band: }

      # 5th source well
      let(:source_well5) { create :well, aliquots: [aliquot5] }
      let(:aliquot5) { create :aliquot, request: request5 }
      let(:request5) { create :scrna_customer_request, request_metadata: request_metadata5 }
      let(:request_metadata5) { create :request_metadata, cells_per_chip_well:, allowance_band: }

      # 6th source well
      let(:source_well6) { create :well, aliquots: [aliquot6] }
      let(:aliquot6) { create :aliquot, request: request6 }
      let(:request6) { create :scrna_customer_request, request_metadata: request_metadata6 }
      let(:request_metadata6) { create :request_metadata, cells_per_chip_well:, allowance_band: }

      # pool with 6 source wells
      let(:pool) { [source_well1, source_well2, source_well3, source_well4, source_well5, source_well6] }

      context 'when there is not enough resuspension volume for the allowance band' do
        it 'stores the modified number of cells per chip well on the destination well' do
          expect(instance_of_test_pooling_class).to receive(:create_new_well_metadata).with(
            Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key],
            Rails.application.config.scrna_config[:allowance_table][allowance_band][6],
            dest_well
          )

          instance_of_test_pooling_class.check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
        end

        it 'errors when the allowance band and number of pools do not match the allowance table' do
          # Stub allowance band and chip_loading_volume to create conditions that do not match the allowance table
          allow(instance_of_test_pooling_class).to receive(:allowance_band_from_request).and_return(
            '1 pool attempt, 1 count'
          )
          allow(instance_of_test_pooling_class).to receive(:calculate_chip_loading_volume).and_return(55.0)

          expect do
            instance_of_test_pooling_class.check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
          end.to raise_error StandardError,
                             'No allowance value found for allowance band 1 pool attempt, 1 count and sample count 6'
        end
      end

      context 'when there is enough resuspension volume for the allowance band' do
        before { allow(instance_of_test_pooling_class).to receive(:calculate_allowance).and_return(60.0) }

        it 'stores the request number of cells per chip well on the destination well' do
          expect(instance_of_test_pooling_class).to receive(:create_new_well_metadata).with(
            Rails.application.config.scrna_config[:number_of_cells_per_chip_well_key],
            cells_per_chip_well,
            dest_well
          )

          instance_of_test_pooling_class.check_pool_for_allowance_band(pool, dest_plate, dest_well_location)
        end
      end
    end
  end
end

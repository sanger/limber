#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Presenters
  module ExtendedCsv

    def self.included(base)
      base.class_eval do

        class_inheritable_reader :bed_prefix

        write_inheritable_attribute :csv, 'show_extended'
        write_inheritable_attribute :bed_prefix, 'PCRXP'
      end
    end

    # Yields information for the show_pooled.csv
    def each_well_transfer(offset=0)
      index = 0
      transfers_for_csv[offset*4...(offset+1)*4].each_with_index do |transfers_list, bed_index|
        transfers_list[:transfers].each do |transfer|
          source_well, destination_wells = transfer
          Array(destination_wells).each do |destination_well|
            yield ({
              :index => (index += 1),
              :name => "#{bed_prefix}#{(offset*4)+bed_index+1}",
              :source_well => source_well,
              :destination_well => destination_well,
              }.merge(transfers_list))
          end
        end
      end
    end

    private

    def all_wells
      return @all_wells unless @all_wells.nil?
      @all_wells = {}
      ('A'..'H').each {|r| (1..12).each{|c| @all_wells["#{r}#{c}"]="H12"}}
      @all_wells
    end

    def transfers_for_csv
      self.labware.creation_transfers.map do |ct|
        source_ean = ct.source.barcode.ean13
        source_barcode = "#{ct.source.barcode.prefix}#{ct.source.barcode.number}"
        source_stock = "#{ct.source.stock_plate.barcode.prefix}#{ct.source.stock_plate.barcode.number}"
        destination_ean = ct.destination.barcode.ean13
        destination_barcode = "#{ct.destination.barcode.prefix}#{ct.destination.barcode.number}"
        transfers = ct.transfers.reverse_merge(all_wells).sort {|a,b| split_location(a.first) <=> split_location(b.first) }
        {
          :source_ean          => source_ean,
          :source_barcode      => source_barcode,
          :source_stock        => source_stock,
          :destination_ean     => destination_ean,
          :destination_barcode => destination_barcode,
          :transfers           => transfers
        }
      end
    end

  end
end

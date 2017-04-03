# frozen_string_literal: true

module Robots
  class SharedBedRobot < Robot
    class Bed < Robot::Bed
      attr_reader :labware

      self.attributes = %i(api user_uuid purpose states label parent target_state robot secondary_purposes)

      def transition
        return if target_state.nil? || labware.empty? # We have nothing to do
        labware.each do |lw|
          StateChangers.lookup_for(lw.purpose.uuid).new(api, lw.uuid, user_uuid).move_to!(target_state, "Robot #{robot.name} started")
        end
      end

      def valid?
        if @barcodes.length != expected_barcode_count
          error("This bed expects #{expected_barcode_count} pieces of labware; #{@barcodes.length} #{@barcodes.one? ? 'was' : 'were'} scanned in.")
        elsif @missing_barcodes.present? # One or more barcodes were not found
          error("Could find labware with the barcode#{@missing_barcodes.one? ? '' : 's'} #{@missing_barcodes.join(', ')}.")
        else
          valid_purposes? && valid_parents?
        end
      end

      def valid_purposes?
        grouped_labware.map do |lw_purpose, lw|
          if lw.count > 1
            error("There are multiple pieces of labware with purpose #{lw.first.purpose.name}, the should be only one.")
          elsif !ordered_purposes.include?(lw_purpose)
            error("#{lw.first.barcode.prefix}#{lw.first.barcode.number} is a #{lw.first.purpose.name}; it should be either a #{secondary_purposes.join(', ')} or #{purpose}.")
          elsif !states.include?(lw.first.state)
            error("#{lw.first.barcode.prefix}#{lw.first.barcode.number} is #{lw.first.state} but it should be #{states}.")
          else
            true
          end
        end.all?
      end

      def valid_parents?
        ordered_purposes.reduce(nil) do |previous, purpose|
          lw = grouped_labware[purpose].first
          expected = lw.parent if previous
          if previous && expected.uuid != previous.uuid
            return error("#{previous.barcode.prefix}#{previous.barcode.number} might be mixed up with #{expected.barcode.prefix}#{expected.barcode.number}")
          end
          lw
        end
        true
      end

      def load(barcodes)
        @barcodes = Array(barcodes).uniq.reject(&:blank?)
        @labware = api.search.find(Settings.searches['Find assets by barcode']).all(Limber::BarcodedAsset, barcode: barcodes)
        @missing_barcodes = barcodes - @labware.map { |lw| lw.barcode.ean13 }
      end

      def purpose_labels
        "#{secondary_purposes.join(',')} and #{purpose}"
      end

      private

      def grouped_labware
        @glw ||= labware.group_by(&:purpose_uuid)
      end

      def expected_barcode_count
        secondary_purposes.length + 1
      end

      def recieving_labware
        grouped_labware.fetch(first_purpose, []).first
      end

      def ordered_purposes
        @op ||= secondary_purposes.map { |sp| Settings.purpose_uuids[sp] } << Settings.purpose_uuids[purpose]
      end

      def first_purpose
        ordered_purposes.first
      end
    end

    def bed_class(bed)
      bed[:secondary_purposes].present? ? Bed : Robot::Bed
    end
    private :bed_class
  end
end

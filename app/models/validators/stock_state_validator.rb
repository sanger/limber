# frozen_string_literal: true

module Validators
  # There are a number of common issues with submission. This validator detects
  # them to provide more feedback to the user. It only gets used
  # if a stock plate is stuck at pending, so performance is not critical
  class StockStateValidator < ActiveModel::Validator
    class Analyzer # rubocop:todo Style/Documentation
      attr_reader :filled_wells, :empty_wells

      def initialize(labware)
        @labware = labware
        analyze_wells
        analyze_pools
      end

      def no_submission?
        @labware.pools.empty?
      end

      def no_samples?
        @filled_wells.empty?
      end

      def duplicates?
        duplicates.present?
      end

      def missing?
        missing.present?
      end

      def empty_wells_with_requests?
        empty_wells_with_requests.present?
      end

      def empty_wells_with_requests
        @empty_wells_with_requests ||= @empty_wells & @well_pools.keys
      end

      def missing
        @missing ||= @filled_wells - @well_pools.keys
      end

      def duplicates
        @duplicates ||= @well_pools.select { |_well, pools| pools.count > 1 }.keys
      end

      private

      def analyze_pools
        @well_pools = Hash.new { |h, i| h[i] = [] }
        @labware.pools.each { |pool| pool.well_locations.each { |well| @well_pools[well] << pool.id } }
      end

      def analyze_wells
        @filled_wells = []
        @empty_wells = []
        @labware.wells.each do |well|
          well.aliquots.empty? ? @empty_wells << well.location : @filled_wells << well.location
        end
      end
    end

    # rubocop:todo Metrics/MethodLength
    def validate(presenter) # rubocop:todo Metrics/AbcSize
      analyzer = Analyzer.new(presenter.labware)
      if analyzer.no_submission?
        presenter.errors.add(:plate, 'has no requests. Please check that your submission built correctly.')
      elsif analyzer.no_samples?
        presenter.errors.add(:plate, 'has no samples. Did the cherry-pick complete successfully?')
      else
        if analyzer.duplicates?
          presenter.errors.add(:plate, "has multiple submissions on: #{analyzer.duplicates.to_sentence}")
        end
        presenter.errors.add(:plate, "has no submissions on: #{analyzer.missing.to_sentence}") if analyzer.missing?
        if analyzer.empty_wells_with_requests?
          presenter.errors.add(:plate, "has requests on empty wells: #{analyzer.empty_wells_with_requests.to_sentence}")
        end
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

# frozen_string_literal: true

module Validators
  # Validator for stock plates that don't require submissions
  # Same as StockStateValidator but skips checks for submissions
  class StockNoSubmissionStateValidator < StockStateValidator
    # rubocop:disable Metrics/MethodLength
    def validate(presenter)
      analyzer = Analyzer.new(presenter.labware)
      if analyzer.no_samples?
        presenter.errors.add(:plate, 'has no samples. Did the cherry-pick complete successfully?')
      else
        if analyzer.duplicates?
          presenter.errors.add(:plate, "has multiple submissions on: #{analyzer.duplicates.to_sentence}")
        end
        if analyzer.empty_wells_with_requests?
          presenter.errors.add(:plate, "has requests on empty wells: #{analyzer.empty_wells_with_requests.to_sentence}")
        end
      end
    end

    # rubocop:enable Metrics/MethodLength
  end
end

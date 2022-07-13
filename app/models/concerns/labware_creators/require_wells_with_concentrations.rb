# frozen_string_literal: true

# Can be included in plate creators which require well aliquots to have concentrations
module LabwareCreators::RequireWellsWithConcentrations
  extend ActiveSupport::Concern

  PLATE_INCLUDES =
    'wells.aliquots,wells.qc_results,wells.requests_as_source.request_type,wells.aliquots.request.request_type'

  def parent
    @parent ||= Sequencescape::Api::V2.plate_with_custom_includes(PLATE_INCLUDES, uuid: parent_uuid)
  end

  # The configuration from the plate purpose.
  def dilutions_config
    purpose_config.fetch(:dilutions)
  end

  # Validation method that can be called to check that all wells with aliquots
  # have an associated qc_result concentration value.
  def wells_with_aliquots_have_concentrations?
    concs_missing = wells_with_missing_concs
    return if concs_missing.empty?

    msg = 'wells missing a concentration (have you uploaded concentrations via QuantHub?):'
    errors.add(:parent, "#{msg} #{concs_missing.join(', ')}")
  end

  private

  def wells_with_missing_concs
    parent
      .wells
      .each_with_object([]) do |well, concs_missing|
        next if well.aliquots.blank?

        concs_missing << well.location if well.latest_concentration.nil?
      end
  end
end

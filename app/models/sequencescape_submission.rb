# frozen_string_literal: true

#
# Class Submission provides an easy means of creating submissions
# via the Sequencescape API
#
# @author Genome Research Ltd.
#
class SequencescapeSubmission
  include ActiveModel::Model

  # Controls the user who is recorded as having made the submission
  # @return [String] user: The uuid of the user who is making the submission
  attr_accessor :user

  # Selects the template to use, by uuid.
  attr_writer :template_uuid

  # Selects the template to use by template name
  attr_writer :template_name

  # A hash of valid request options for the submission
  # @return [Hash] request_options: The request options to use
  attr_accessor :request_options

  # @return [Array<Hash>] Returns a nested array of asset_group object. Each
  #                       asset group is a hash containing:
  #                       assets: Array of asset uuids
  #                       study: The study uuid
  #                       project: The project uuid
  attr_reader :asset_groups

  attr_accessor :allowed_extra_barcodes, :extra_barcodes, :num_extra_barcodes, :labware_barcode, :submission_uuid

  validates :user, :assets, :template_uuid, :request_options, presence: true
  validate :check_extra_barcodes

  #
  # Sends the submission to Sequencescape
  #
  # @return [TrueClass] true Returns true on success
  #
  def save
    return false unless valid?

    generate_submissions
  end

  # @return [String] template_uuid: The uuid of the submission template to use
  def template_uuid
    @template_uuid ||= Settings.submission_templates[@template_name]
  end

  #
  # Sets up a single asset group containing the supplied assets
  #
  # @param asset_uuids [Array<String>] Array of asset uuids to submit
  #
  def assets=(asset_uuids)
    @asset_groups = [{ asset_uuids: }]
  end

  #
  # An array of all asset uuids that will be submitted
  #
  # @return [Array<String>] Array of asset uuids to submit
  #
  def assets
    @asset_groups.pluck(:asset_uuids).flatten
  end

  def extra_barcodes_trimmed
    return nil unless extra_barcodes

    extra_barcodes.map(&:strip).compact_blank
  end

  def extra_plates
    return @extra_plates if @extra_plates

    response = Sequencescape::Api::V2.additional_plates_for_presenter(barcode: extra_barcodes_trimmed)
    @extra_plates ||= response
    raise "Barcodes not found #{extra_barcodes}" unless @extra_plates

    @extra_plates
  end

  def extra_assets
    return [] unless extra_plates

    @extra_assets ||= extra_plates.map { |labware| labware.wells.compact_blank.map(&:uuid) }.flatten.uniq
  end

  #
  # Set asset_groups for the submission
  #
  # @param asset_groups [Array<Hash>, Hash<Hash>]
  #   Nested array asset_group hashes. (See #asset_groups) Also
  #   accepts hash to support HTML forms, where each value is an array of asset
  #   uuids, indicating an asset group. Keys are ignored.
  #
  def asset_groups=(asset_groups)
    groups = asset_groups.respond_to?(:values) ? asset_groups.values : asset_groups
    @asset_groups =
      groups.map do |group|
        group[:asset_uuids] = group[:assets] if group[:assets]
        group.except(:assets)
      end
  end

  def asset_groups_for_orders_creation
    return asset_groups unless (asset_groups.length == 1) && extra_barcodes

    [{ asset_uuids: [assets, extra_assets].flatten.compact, autodetect_studies: true, autodetect_projects: true }]
  end

  private

  def generate_orders
    asset_groups_for_orders_creation.map do |asset_group|
      Sequencescape::Api::V2::Order.create!(
        submission_template_attributes: { request_options: request_options, user_uuid: user }.merge(asset_group),
        submission_template_uuid: template_uuid
      )
    end
  end

  def generate_submissions
    orders = generate_orders
    @submission_uuid =
      Sequencescape::Api::V2::Submission.create!(
        and_submit: true,
        order_uuids: orders.map(&:uuid),
        user_uuid: user
      ).uuid
    true
  rescue JsonApiClient::Errors::ConnectionError => e
    errors.add(:sequencescape_connection, e.message)
    false
  rescue JsonApiClient::Errors::RecordNotSaved => e
    errors.add(:submission, e.record.errors.full_messages.join('; '))
    false
  end

  # I think rubocop's suggestions make it less readable
  # rubocop:disable Style/GuardClause
  def check_extra_barcodes
    return unless extra_barcodes

    if extra_barcodes_trimmed.size != extra_barcodes_trimmed.uniq.size
      errors.add(:submission, 'Additional scanned barcodes should not include duplicates')
    end

    if extra_barcodes_trimmed.include? labware_barcode
      errors.add(
        :submission,
        'Any scanned additional barcodes should not include the barcode of the current plate - ' \
        'that will automatically be included'
      )
    end
  end
  # rubocop:enable Style/GuardClause
end

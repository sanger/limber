# frozen_string_literal: true

#
# Class Submission provides an easy means of creating submissions
# via the Sequencescape API
#
# @author Genome Research Ltd.
#
class SequencescapeSubmission
  include ActiveModel::Model

  # Sets the api through which objects will be created
  # @return [Sequencescape::Api] api A functional Sequencescape::Api object
  attr_accessor :api

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

  validates :api, :user, :assets, :template_uuid, :request_options, presence: true
  validate :check_extra_barcodes

  PERF_LOG = Logger.new("#{Rails.root}/log/seq_subm_performance.log")
  PERF_LOG.formatter = Logger::Formatter.new
  PERF_LOG.level = Logger::INFO

  #
  # Sends the submission to Sequencescape
  #
  # @return [TrueClass] true Returns true on success
  #
  def save
    return false unless valid?
    PERF_LOG.info "Start generate submissions"
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
    @asset_groups = [{ assets: asset_uuids }]
  end

  #
  # An array of all asset uuids that will be submitted
  #
  # @return [Array<String>] Array of asset uuids to submit
  #
  def assets
    @asset_groups.pluck(:assets).flatten
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
    @asset_groups = asset_groups.respond_to?(:values) ? asset_groups.values : asset_groups
  end

  def asset_groups_for_orders_creation
    return asset_groups unless (asset_groups.length == 1) && extra_barcodes

    [{ assets: [assets, extra_assets].flatten.compact, autodetect_studies_projects: true }]
  end

  private

  def generate_orders
    PERF_LOG.info "Start generate_orders"
    order_index = 1
    asset_groups_for_orders_creation.map do |asset_group|
      PERF_LOG.info "Start order #{order_index}"
      order_parameters = { request_options: request_options, user: user }.merge(asset_group)
      # try passing a list of orders to this instead of one at a time
      # or try one order and pass the request options
      order_index += 1
      submission_template.orders.create!(order_parameters)
    end
  end

  # rubocop:disable Metrics/AbcSize
  def generate_submissions
    orders = generate_orders
    PERF_LOG.info "End generate orders and start submission create"
    submission = api.submission.create!(orders: orders.map(&:uuid), user: user)
    @submission_uuid = submission.uuid
    PERF_LOG.info "Start submission submit"
    submission.submit!
    PERF_LOG.info "End submission submit"
    true
  rescue Sequencescape::Api::ConnectionFactory::Actions::ServerError => e
    errors.add(:sequencescape_connection, /.+\[([^\]]+)\]/.match(e.message)[1])
    false
  rescue Sequencescape::Api::ResourceInvalid => e
    errors.add(:submission, e.resource.errors.full_messages.join('; '))
    false
  end

  # rubocop:enable Metrics/AbcSize

  def submission_template
    @submission_template ||= api.order_template.find(template_uuid)
  end

  def check_extra_barcodes
    return unless extra_barcodes

    if extra_barcodes_trimmed.size != extra_barcodes_trimmed.uniq.size
      errors.add(:submission, 'Additional scanned barcodes should not include duplicates')
    end

    return unless extra_barcodes_trimmed.include? labware_barcode

    errors.add(
      :submission,
      'Any scanned additional barcodes should not include the barcode of the current plate - ' \
        'that will automatically be included'
    )
  end
end

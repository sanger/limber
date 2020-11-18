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
  # @return [Array<Array<String>>] Returns a nested array of asset uuids, each
  #                                group of ids represents an asset group, and
  #                                will form a separate order
  attr_reader :asset_groups

  validates :api, :user, :assets, :template_uuid, :request_options, presence: true

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
    @asset_groups = [asset_uuids]
  end

  #
  # An array of all asset uuids that will be submitted
  #
  # @return [Array<String>] Array of asset uuids to submit
  #
  def assets
    @asset_groups.flatten
  end

  #
  # Set
  #
  # @param assets [Array<Array<String>>, Hash<Array>]
  #   Nested array of asset_uuids, grouped together into asset groups. Also
  #   accepts hash to support HTML forms, where each value is an array of asset
  #   uuids, indicating an asset group. Keys are ignored.
  #
  def asset_groups=(assets)
    @asset_groups = if assets.respond_to?(:values)
                      assets.values
                    else
                      assets
                    end
  end

  private

  def generate_orders
    asset_groups.map do |asset_uuids|
      submission_template.orders.create!(
        assets: asset_uuids,
        request_options: request_options,
        user: user
      )
    end
  end

  # rubocop:todo Metrics/MethodLength
  def generate_submissions # rubocop:todo Metrics/AbcSize
    orders = generate_orders

    submission = api.submission.create!(
      orders: orders.map(&:uuid),
      user: user
    )

    submission.submit!
    true
  rescue Sequencescape::Api::ConnectionFactory::Actions::ServerError => e
    errors.add(:sequencescape_connection, /.+\[([^\]]+)\]/.match(e.message)[1])
    false
  rescue Sequencescape::Api::ResourceInvalid => e
    errors.add(:submission, e.resource.errors.full_messages.join('; '))
    false
  end
  # rubocop:enable Metrics/MethodLength

  def submission_template
    api.order_template.find(template_uuid)
  end
end

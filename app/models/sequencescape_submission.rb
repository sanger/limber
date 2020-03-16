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
  # Sets the assets which will be input into the submission
  # @return [Array] assets: Array of asset uuids to submit
  attr_accessor :assets
  # Selects the template to use, by uuid.
  # @return [String] template_uuid: The uuid of the submission template to use
  attr_accessor :template_uuid
  # A hash of valid request options for the submission
  # @return [Hash] request_options: The request options to use
  attr_accessor :request_options

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

  private

  def generate_submissions
    order = submission_template.orders.create!(
      assets: assets,
      request_options: request_options,
      user: user
    )

    submission = api.submission.create!(
      orders: [order.uuid],
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

  def submission_template
    api.order_template.find(template_uuid)
  end
end

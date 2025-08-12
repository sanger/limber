# frozen_string_literal: true

# Represents a package of work requested in Sequencescape. Responsible
# for building requests, and downstream labware and receptacles.
class Sequencescape::Api::V2::Submission < Sequencescape::Api::V2::Base
  property :state, type: :string_inquirer
  property :created_at, type: :time
  property :updated_at, type: :time
  property :lanes_of_sequencing, type: :integer
  property :multiplexed?, type: :boolean

  delegate :building?, :pending?, :processing?, :ready?, :failed?, :cancelled?, to: :state

  # In practice the transaction tends to hide submissions in the processing state,
  # and we'll see them jump straight from pending to built. However this can
  # probably be considered a bug so lets handle both states here to avoid
  # unpleasant side effects in future.
  # We also have a 'ready_buffer', an optional argument which tells us to treat
  # anything that completed more recently than the ready_buffer as still pending.
  # This lets us handle some race conditions that can occur.
  def building_in_progress?(ready_buffer: 0.seconds)
    pending? || processing? || (ready? && updated_at > ready_buffer.ago)
  end
end

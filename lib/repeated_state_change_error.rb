# frozen_string_literal: true

# This class rescues any exceptions where the source and target states are the same
# but the transition is invalid.
class RepeatedStateChangeError < Sequencescape::Api::ConnectionFactory::Actions::ServerError
  # rescue automatically uses the match operator (===) to identify exceptions to rescue
  def self.===(other)
    other.is_a?(Sequencescape::Api::ConnectionFactory::Actions::ServerError) && repeated_state_change_error?(other)
  end

  def self.repeated_state_change_error?(exception)
    error = JSON.parse(exception.message).dig('general', 0)
    match_data = /\ANo obvious transition from "([^"]+)" to "([^"]+)"\z/.match(error)
    (match_data || false) &&
      match_data[1] == match_data[2]
  end
end

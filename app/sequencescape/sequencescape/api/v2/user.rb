# frozen_string_literal: true

# Represents a user in Limber via the Sequencescape API
class Sequencescape::Api::V2::User < Sequencescape::Api::V2::Base
  def name
    "#{first_name} #{last_name}"
  end
end

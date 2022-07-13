# frozen_string_literal: true

class Limber::User < Sequencescape::User # rubocop:todo Style/Documentation
  def name
    @name ||= first_name || last_name ? "#{first_name} #{last_name}".strip : login
  end
end

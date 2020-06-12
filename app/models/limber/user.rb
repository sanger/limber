# frozen_string_literal: true

class Limber::User < Sequencescape::User # rubocop:todo Style/Documentation
  def name
    @name ||= if first_name || last_name
                "#{first_name} #{last_name}".strip
              else
                login
              end
  end
end

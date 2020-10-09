# frozen_string_literal: true

class Sequencescape::Api::V2::PrimerPanel < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
  UNKNOWN = 'Unknown'

  def program_name_for(step)
    program_for(step).fetch('name', UNKNOWN)
  end

  def program_duration_for(step)
    program_for(step).fetch('duration', UNKNOWN)
  end

  private

  def program_for(step)
    programs.fetch(step, {})
  end
end

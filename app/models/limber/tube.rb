# frozen_string_literal: true

class Limber::Tube < Sequencescape::Tube # rubocop:todo Style/Documentation
  alias plate_purpose purpose

  # Mocked out for the time being
  def in_progress_submission_uuids
    []
  end

  def plate?
    false
  end

  def tube?
    true
  end
end

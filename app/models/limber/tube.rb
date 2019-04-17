# frozen_string_literal: true

# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;

class Limber::Tube < Sequencescape::Tube
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

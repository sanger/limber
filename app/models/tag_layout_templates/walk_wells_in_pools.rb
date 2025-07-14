# frozen_string_literal: true

module TagLayoutTemplates::WalkWellsInPools # rubocop:todo Style/Documentation
  def generate_tag_layout(_plate)
    # This code was complicated, and its behaviour isn't
    # entirely apparent. (Something to do with optimising robots)
    # It doesn't particularly make sense in the context of
    # tag plates either. So we'll just remove it, throw unacceptable_tag_layout
    # instead. Not a fan of throws either, but at least that is handled.
    # Essentially this ensures that any templates that are 'by pool'
    # will not get accepted.
    throw :unacceptable_tag_layout
  end
end

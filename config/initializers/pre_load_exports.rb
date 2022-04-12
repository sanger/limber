# frozen_string_literal: true

# It isn't entirely necessary that we pre-load our exports, however it lets
# us know of invalid configurations upfront, rather than at runtime.
Rails.application.config.to_prepare do
  Export.loader
end

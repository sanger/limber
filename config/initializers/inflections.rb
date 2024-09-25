# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# The `inflect.acronym` function allows you to specify how Rails
# parses, splits, and capitalizes words for class/test/filename
# translations - particularly useful for acronyms which tend to not
# play well with Rail's `camelize` function.
# See https://api.rubyonrails.org/classes/ActiveSupport/Inflector/Inflections.html#method-i-acronym

ActiveSupport::Inflector.inflections(:en) do |inflect|
  # inflect.acronym 'RESTful' # supported but not enabled by default
  inflect.uncountable %w[sample_metadata request_metadata]
  inflect.acronym 'SCRNA'
end

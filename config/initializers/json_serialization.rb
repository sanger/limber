# frozen_string_literal: true

###
# Skips escaping HTML entities and line separators. When set to `false`, the
# JSON renderer no longer escapes these to improve performance.
#
# Example:
#   class PostsController < ApplicationController
#     def index
#       render json: { key: "\u2028\u2029<>&" }
#     end
#   end
#
# Renders `{"key":"\u2028\u2029\u003c\u003e\u0026"}` with the previous default, but `{"key":"  <>&"}` with the config
# set to `false`.
#
# Applications that want to keep the escaping behavior can set the config to `true`.
#++
Rails.configuration.action_controller.escape_json_responses = true # likely required for qc file uploads

###
# Skips escaping LINE SEPARATOR (U+2028) and PARAGRAPH SEPARATOR (U+2029) in JSON.
#
# Historically these characters were not valid inside JavaScript literal strings but that changed in ECMAScript 2019.
# As such it's no longer a concern in modern browsers: https://caniuse.com/mdn-javascript_builtins_json_json_superset.
#++
Rails.configuration.active_support.escape_js_separators_in_json = true # likely required for qc file uploads

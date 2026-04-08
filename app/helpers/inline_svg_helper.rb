# frozen_string_literal: true

require_relative '../../lib/vite_inline_svg_file_loader'

# This helper adds role=img to the <svg> element and also accepts an optional
# title argument for dynamically inserting a <title>. These are important for
# improving accessibility.
# https://mattbrictson.com/blog/inline-svg-with-vite-rails#is-the-inline_svg-gem-always-necessary
module InlineSvgHelper
  # Generates an inline SVG tag for a given filename. Optionally adds a title element within the SVG for accessibility.
  # Note that the output is marked as safe, so make sure the provided SVG file is trusted.
  # @param filename [String] the name of the SVG file to be inlined.
  # @return [String] HTML safe string containing the inline SVG with or without a title.
  def inline_svg_tag(filename, **attributes)
    attributes[:role] = 'img'
    attributes_string = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(' ')
    svg = ViteInlineSvgFileLoader.named(filename)
    svg = svg.sub('<svg', "<svg #{attributes_string}")
    svg.strip.html_safe # rubocop:disable Rails/OutputSafety
  end
end

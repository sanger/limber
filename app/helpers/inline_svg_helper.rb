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
  # @param title [String, nil] the title to be added inside the SVG. If provided, it enhances accessibility by describing the SVG.
  # @return [String] HTML safe string containing the inline SVG with or without a title.
  def inline_svg_tag(filename, title: nil)
    svg = ViteInlineSvgFileLoader.named(filename)
    svg = svg.sub(/\A<svg/, '<svg role="img"')
    svg = svg.sub(/\A<svg.*?>/, safe_join(['\0', "\n", tag.title(title)])) if title.present?

    svg.strip.html_safe # rubocop:disable Rails/OutputSafety
  end
end

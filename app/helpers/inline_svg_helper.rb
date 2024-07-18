require_relative '../../lib/vite_inline_svg_file_loader.rb'

module InlineSvgHelper
  # This helper adds role=img to the <svg> element and also accepts an optional
  # title argument for dynamically inserting a <title>. These are important for
  # improving accessibility.
  # https://mattbrictson.com/blog/inline-svg-with-vite-rails#is-the-inline_svg-gem-always-necessary
  def inline_svg_tag(filename, title: nil)
    svg = ViteInlineSvgFileLoader.named(filename)
    svg = svg.sub(/\A<svg/, '<svg role="img"')
    svg = svg.sub(/\A<svg.*?>/, safe_join(['\0', "\n", tag.title(title)])) if title.present?

    svg.strip.html_safe
  end
end

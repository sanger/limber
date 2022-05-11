# frozen_string_literal: true

# We have a large number of pre-calculated colours
# Unfortunately the lightness method in SASS doesn't take into
# account human eye sensitivity, and claims #ffff00 is 50% bright
# This tool uses w3c recommendations to calculate whether white
# or black text has better contrast for a given colour.
# https://www.w3.org/TR/WCAG20-TECHS/G17.html#G17-tests
class ColourConverter
  HEX = /#([0-f]{2})([0-f]{2})([0-f]{2})/.freeze

  RED_MULTIPLIER = 0.2126
  GREEN_MULTIPLIER = 0.7152
  BLUE_MULTIPLIER = 0.0722

  attr_reader :hex

  def self.white
    ColourConverter.new('#ffffff')
  end

  def self.black
    ColourConverter.new('#000000')
  end

  # An individual colour chanel, eg. red, green or blue
  class ColourChanel
    def initialize(hex_value)
      @value = hex_value.hex / 255.0
    end

    def luminance
      @value <= 0.03928 ? @value / 12.92 : ((@value + 0.055) / 1.055)**2.4
    end
  end

  def initialize(hex)
    @hex = hex
    matched = HEX.match(hex)
    @red = ColourChanel.new(matched[1])
    @green = ColourChanel.new(matched[2])
    @blue = ColourChanel.new(matched[3])
  end

  def luminance
    @luminance ||=
      (RED_MULTIPLIER * @red.luminance) + (GREEN_MULTIPLIER * @green.luminance) + (BLUE_MULTIPLIER * @blue.luminance)
  end

  def contrast_ratio(other)
    darker, lighter = [self, other].sort_by(&:luminance)
    (lighter.luminance + 0.05) / (darker.luminance + 0.05)
  end

  def highest_contrast_ratio(*candidates)
    candidates.max_by { |candidate| contrast_ratio(candidate) }
  end

  def black_or_white
    highest_contrast_ratio(ColourConverter.white, ColourConverter.black).hex
  end
end

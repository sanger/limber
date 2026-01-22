# frozen_string_literal: true

# A QcFile from sequencescape via the V2 API
class Sequencescape::Api::V2::QcFile < Sequencescape::Api::V2::Base
  has_one :labware

  property :created_at, type: :time

  # The endpoint requires that the labware relationship is of a Labware type.
  # Since we create for plates and tubes, not the more generic labware type, we will declare the relationship manually.
  def self.create_for_labware!(labware:, contents:, filename:)
    sanitized_contents = sanitize_contents(contents)

    relationships = { labware: { data: { id: labware.id, type: 'labware' } } }
    create!(contents: sanitized_contents, filename: filename, relationships: relationships)
  end

  def self.sanitize_contents(raw_contents)
    # Force binary encoding so we start from a known state
    contents = raw_contents.dup.force_encoding('ASCII-8BIT')

    # Try to transcode to UTF-8, raise if invalid bytes encountered
    begin
      utf8_contents = contents.encode('UTF-8')
    rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError => e
      raise JSON::GeneratorError, "Invalid UTF-8 encoding in uploaded file: #{e.message}"
    end

    utf8_contents
  end
end

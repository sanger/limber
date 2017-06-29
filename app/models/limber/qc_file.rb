# frozen_string_literal: true

class Limber::QcFile < Sequencescape::QcFile
  # Done this here for the moment, could look at using
  # ActiveModel::Serializers in future.
  def as_json(_args)
    { filename: filename, size: size, uuid: uuid, created: created_at.to_formatted_s(:long) }
  end
end

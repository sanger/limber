# frozen_string_literal: true

class Limber::QcFile < Sequencescape::QcFile # rubocop:todo Style/Documentation
  # Done this here for the moment, could look at using
  # ActiveModel::Serializers in future.
  def as_json(_args)
    { filename:, size:, uuid:, created: created_at.to_fs(:long) }
  end
end

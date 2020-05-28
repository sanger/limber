# frozen_string_literal: true

class Sequencescape::Api::V2::Aliquot < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
  belongs_to :request
  has_one :sample

  def tagged?
    tag_oligo.present? || tag2_oligo.present?
  end
end

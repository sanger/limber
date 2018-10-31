# frozen_string_literal: true

class Sequencescape::Api::V2::Aliquot < Sequencescape::Api::V2::Base
  belongs_to :request
  belongs_to :sample

  def tagged?
    tag_oligo.present? || tag2_oligo.present?
  end
end

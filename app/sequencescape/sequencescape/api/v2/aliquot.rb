# frozen_string_literal: true

class Sequencescape::Api::V2::Aliquot < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
  # requires shallow path otherwise get a resource not found issue TODO: where/when do we get this?
  belongs_to :request, shallow_path: true
  has_one :sample
  has_one :study
  has_one :project
  has_one :receptacle

  def tagged?
    tag_oligo.present? || tag2_oligo.present?
  end

  # This is our best attempt at mimicking the equivalent aliquot behaviour
  # over in Sequencescape Aliquot::equivalent_attributes
  # We use a smaller subset of attributes here, to avoid sending everything over
  # the api. In future we could consider:
  # 1. Sending over all attributes
  # 2. Hashing the attributes sequencescape side and sending that over.
  # But for the moment this will suffice, as in practice existing process
  # should ensure that these values are sufficient.
  # In the event these assumptions are violated, Sequencescape will still prevent
  # the transfer, it just wont be as user-friendly.
  def equivalent_attributes
    [request_id || request.id, suboptimal]
  end

  # Returns the combination of tag and tag2 oligos for the aliquot
  def tag_pair
    [tag_oligo, tag2_oligo]
  end

  def order_group
    [relationships.study.dig(:data, :id), relationships.project.dig(:data, :id)]
  end
end

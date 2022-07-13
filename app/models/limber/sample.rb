# frozen_string_literal: true

# API V1 sample, extends the sequencescape-client-api implementation
# to provide API compatability with the V2 implementation
class Limber::Sample < Sequencescape::Sample
  delegate :sample_id, to: :sanger, prefix: true

  def species
    taxonomy.common_name
  end
end

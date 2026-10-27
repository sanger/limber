# frozen_string_literal: true

# An Ultima application chosen in the Ultima conversion submission, e.g.
# 10x Flex v2. The lab uses its UGA and UGB primers with the Ultima tags.
class Sequencescape::Api::V2::UltimaApplication < Sequencescape::Api::V2::Base
  DEFAULT_INCLUDES = %i[uga_primer ugb_primer].freeze

  has_one :uga_primer, class_name: 'Sequencescape::Api::V2::UltimaPrimer'
  has_one :ugb_primer, class_name: 'Sequencescape::Api::V2::UltimaPrimer'

  def self.find_all(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::UltimaApplication
      .includes(*includes)
      .where(**options)
      .all
  end
end

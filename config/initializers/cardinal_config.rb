# frozen_string_literal: true

require 'csv'
cardinal_pooling_csv = CSV.read('config/cardinal_pooling.csv', { encoding: 'UTF-8', headers: true, header_converters: :symbol, converters: :all })

LabwareCreators::CardinalPoolsPlate.pooling_config = {}

cardinal_pooling_csv.each do |data|
  contents = data.to_hash
  number_of_pools = data.to_hash.values.compact.count - 1

  # -1 Because we don't want to include :number column
  LabwareCreators::CardinalPoolsPlate.pooling_config[contents[:number]] = number_of_pools
end

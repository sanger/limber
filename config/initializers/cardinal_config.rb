# frozen_string_literal: true

require 'csv'
cardinal_pooling_csv = CSV.read('config/cardinal_pooling.csv', { encoding: 'UTF-8', headers: true, header_converters: :symbol, converters: :all })

Rails.application.config.cardinal_pooling_config = {}

cardinal_pooling_csv.each do |data|
  contents = data.to_hash
  number_of_pools = data.to_hash.values.compact.count - 1

  Rails.application.config.cardinal_pooling_config[contents[:number]] = number_of_pools
end

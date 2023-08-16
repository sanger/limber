# frozen_string_literal: true

require 'csv'
scrna_core_cell_extraction_pooling_csv =
  CSV.read(
    'config/scrna_core_cell_extraction_pooling.csv',
    { encoding: 'UTF-8', headers: true, header_converters: :symbol, converters: :all }
  )

Rails.application.config.scrna_core_cell_extraction_pooling_config = {}

scrna_core_cell_extraction_pooling_csv.each do |data|
  contents = data.to_hash
  Rails.application.config.scrna_core_cell_extraction_pooling_config[contents[:number]] = contents[:number_of_pools]
end

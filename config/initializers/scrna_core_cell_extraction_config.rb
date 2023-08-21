# frozen_string_literal: true

require 'csv'
scrna_core_cell_extraction_pooling_csv =
  CSV.read(
    'config/cardinal_pooling.csv',
    { encoding: 'UTF-8', headers: true, header_converters: :symbol, converters: :all }
  )

Rails.application.config.scrna_core_cell_extraction_pooling_config = {
  # We should be able to do an automated submission similar to Cardinal, but instead of specifying a
  # hardcoded study and project in the submission template ("Project Cardinal Combined", for
  # Cardinal), we can use the `autodetect_studies_projects flag`` - because all the samples on a
  # plate should be under the same study for 007c Phase 1 (Lesley, in Slack).
  # (For Phase 2, they may be mixed on the same 10X chip, but that doesn't affect this story as will
  # be a separate submission).
  autodetect_studies_projects: true,
}

scrna_core_cell_extraction_pooling_csv.each do |data|
  contents = data.to_hash
  Rails.application.config.scrna_core_cell_extraction_pooling_config[contents[:number]] = contents[:number_of_pools]
end

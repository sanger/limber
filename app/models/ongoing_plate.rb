# frozen_string_literal: true

# Simple class to handle form input for searching
class OngoingPlate < AssetSearchForm
  self.form_partial = 'plate_search_form'

  def search_parameters
    {
      states: states || %w[pending started passed qc_complete failed cancelled],
      plate_purpose_uuids: purpose_uuids,
      show_my_plates_only: show_my_plates_only == '1',
      include_used: include_used == '1',
      page: page
    }
  end

  def default_purposes
    Settings.purposes.select { |_uuid, settings| settings[:asset_type] == 'plate' }.keys
  end
end

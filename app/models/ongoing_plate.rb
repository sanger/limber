# frozen_string_literal: true

# Simple class to handle form input for searching
class OngoingPlate < AssetSearchForm
  self.form_partial = 'plate_search_form'

  def search_parameters
    {
      state: states || %w[pending started passed qc_complete failed cancelled],
      purpose_name: purpose_names,
      include_used: include_used == '1'
    }
  end

  def pagination
    return {} if page.nil? # No pagination

    { page: page, per_page: PER_PAGE }
  end

  def default_purposes
    Settings.purposes.select { |_uuid, settings| settings[:asset_type] == 'plate' }.keys
  end
end

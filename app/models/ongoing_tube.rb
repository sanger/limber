# frozen_string_literal: true

# Simple class to handle form input for searching
class OngoingTube < AssetSearchForm
  self.form_partial = 'tube_search_form'

  def search_parameters
    {
      states: states || %w[pending started passed qc_complete failed cancelled],
      tube_purpose_uuids: purpose_uuids,
      include_used: include_used == '1',
      page: page
    }
  end

  def v2_search_parameters
    { purpose_name: purpose_names, include_used: include_used == '1' }
  end

  def v2_pagination
    { number: page, size: 30 }
  end

  def default_purposes
    Settings.purposes.select { |_uuid, settings| settings[:asset_type] == 'tube' }.keys
  end
end

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

  # @note
  # This is currently only being used by the SearchController, as other usages pass in `purposes`,
  #   and therefore don't use the default_purposes method.
  #   We are returning an empty array here, because there are hundreds of plate purposes in the database,
  #   and the GET query was exceeding the maximum number of bytes.
  #   Instead, the page can load, then the user can then select a purpose from the list, which will be paginated.
  def default_purposes
    []
  end
end

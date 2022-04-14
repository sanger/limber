# frozen_string_literal: true

require 'spec_helper'

# CreationForm is the base class for our forms
RSpec.describe Limber::Plate do
  has_a_working_api

  subject(:plate) { build :plate, transfer_request_collections_count: 2 }
  let(:transfer_request_collections_json) { json :transfer_request_collection_collection }

  before do
    stub_api_get(plate.uuid, 'wells', body: json(:well_collection))
    stub_api_get(plate.uuid, 'transfer_request_collections', body: transfer_request_collections_json)
  end
end

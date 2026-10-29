# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeProxyPolicy do
  describe '.allowed?' do
    [
      %w[GET labware],
      %w[get labware/12],
      %w[GET labware/12/comments],
      %w[GET plates?filter[barcode]=DN1&include=wells],
      %w[GET tag_sets],
      %w[GET tag_groups],
      %w[GET qcables?filter[barcode]=1],
      %w[POST comments],
      %w[POST qc_assays],
      %w[POST custom_metadatum_collections],
      %w[PATCH custom_metadatum_collections/3]
    ].each do |verb, path|
      it "allows #{verb} #{path}" do
        expect(described_class.allowed?(verb, path)).to be true
      end
    end

    [
      %w[GET api_keys],
      %w[POST labware],
      %w[PATCH comments/1],
      %w[DELETE comments/1],
      %w[PUT comments/1],
      %w[GET ../admin],
      %w[GET labware/../users],
      %w[GET labware/%2e%2e/users],
      %w[GET /labware],
      %w[GET //evil.com/labware],
      %w[GET http://evil.com/labware],
      ['GET', 'labware\\..\\users'],
      ['GET', ''],
      ['GET', nil]
    ].each do |verb, path|
      it "denies #{verb} #{path.inspect}" do
        expect(described_class.allowed?(verb, path)).to be false
      end
    end
  end
end

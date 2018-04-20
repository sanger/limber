require "spec_helper"

describe "plates/library_pool.csv.erb" do

  context "with a full plate" do
    has_a_working_api

    let(:labware) { build(:plate)  }

    before(:each) do
      assign(:presenter, Presenters::PlatePresenter.new(api: api, labware: labware ))
      stub_api_get(labware.uuid, 'wells', body: json(:well_collection))
    end

    let(:expected_content) do
      [
        ['Plate Barcode','DN1'],
        ['Plate Purpose','example-purpose'],
        [],
        ['Well','Concentration','Pick','Pool'],
        ['A1',0,1]
      ]
    end

    it "renders the expected content" do
      expect(CSV.parse(render)).to eq(expected_content)
    end
  end
end

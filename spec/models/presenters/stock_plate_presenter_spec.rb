# frozen_string_literal: true

describe Presenters::StockPlatePresenter do
  has_a_working_api(times: 2)

  let(:labware) { build :stock_plate }

  subject do
    Presenters::StockPlatePresenter.new(
      api:     api,
      labware: labware
    )
  end

  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end
end

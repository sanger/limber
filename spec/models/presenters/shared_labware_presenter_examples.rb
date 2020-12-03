# frozen_string_literal: true

RSpec.shared_examples 'a labware presenter' do
  it 'returns labware' do
    expect(subject.labware).to eq(labware)
  end

  it 'provides a title' do
    expect(subject.title).to eq(title)
  end

  it 'has a state' do
    expect(subject.state).to eq(state)
  end

  it 'has a summary' do
    expect { |b| subject.summary(&b) }.to yield_successive_args(*summary_tab)
  end

  it 'has a sidebar partial' do
    expect(subject.sidebar_partial).to eq(sidebar_partial)
  end

  it 'responds to child_assets' do
    expect(subject).to respond_to(:child_assets)
  end
end

RSpec.shared_examples 'a stock presenter' do
  it 'prevents state change' do
    expect { |b| subject.default_state_change(&b) }.not_to yield_control
  end

  it 'displays its own barcode as stock' do
    expect(subject.input_barcode).to eq(barcode_string)
  end
end

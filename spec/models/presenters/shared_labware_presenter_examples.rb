# frozen_string_literal: true
shared_examples 'a labware presenter' do
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
    # If you don't expect to trigger any request, just use let(:expected_requests_for_summary) {}
    expect { |b| subject.summary(&b) }.to yield_successive_args(*summary_tab)
  end
end

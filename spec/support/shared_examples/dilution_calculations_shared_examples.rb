# frozen_string_literal: true

RSpec.shared_examples 'it constructs destination qc assay attributes' do
  let(:transfer_hash) do
    {
      'A1' => { 'dest_locn' => 'A2', 'dest_conc' => BigDecimal('0.665'), 'volume' => BigDecimal('20.0') },
      'B1' => { 'dest_locn' => 'A1', 'dest_conc' => BigDecimal('0.343'), 'volume' => BigDecimal('20.0') },
      'C1' => { 'dest_locn' => 'A3', 'dest_conc' => BigDecimal('2.135'), 'volume' => BigDecimal('20.0') }
    }
  end
  let(:expected_attributes) do
    [
      {
        'uuid' => 'child_uuid',
        'well_location' => 'A2',
        'key' => 'concentration',
        'value' => BigDecimal('0.665'),
        'units' => 'ng/ul',
        'cv' => 0,
        'assay_type' => subject.class.name.demodulize,
        'assay_version' => assay_version
      },
      {
        'uuid' => 'child_uuid',
        'well_location' => 'A1',
        'key' => 'concentration',
        'value' => BigDecimal('0.343'),
        'units' => 'ng/ul',
        'cv' => 0,
        'assay_type' => subject.class.name.demodulize,
        'assay_version' => assay_version
      },
      {
        'uuid' => 'child_uuid',
        'well_location' => 'A3',
        'key' => 'concentration',
        'value' => BigDecimal('2.135'),
        'units' => 'ng/ul',
        'cv' => 0,
        'assay_type' => subject.class.name.demodulize,
        'assay_version' => assay_version
      }
    ]
  end

  it 'creates the expected attibutes' do
    expect(subject.construct_dest_qc_assay_attributes('child_uuid', transfer_hash)).to eq(expected_attributes)
  end
end

RSpec.shared_examples 'it extracts destination concentrations' do
  let(:transfer_hash) do
    {
      'A1' => { 'dest_locn' => 'A2', 'dest_conc' => BigDecimal('0.665') },
      'B1' => { 'dest_locn' => 'A1', 'dest_conc' => BigDecimal('0.343') },
      'C1' => { 'dest_locn' => 'A3', 'dest_conc' => BigDecimal('2.135') },
      'D1' => { 'dest_locn' => 'B3', 'dest_conc' => BigDecimal('3.123') },
      'E1' => { 'dest_locn' => 'C3', 'dest_conc' => BigDecimal('3.045') },
      'F1' => { 'dest_locn' => 'B2', 'dest_conc' => BigDecimal('0.743') },
      'G1' => { 'dest_locn' => 'C2', 'dest_conc' => BigDecimal('0.693') }
    }
  end
  let(:expected_dest_concs) do
    {
      'A2' => BigDecimal('0.665'),
      'A1' => BigDecimal('0.343'),
      'A3' => BigDecimal('2.135'),
      'B3' => BigDecimal('3.123'),
      'C3' => BigDecimal('3.045'),
      'B2' => BigDecimal('0.743'),
      'C2' => BigDecimal('0.693')
    }
  end

  it 'refactors the transfers hash correctly' do
    expect(subject.extract_destination_concentrations(transfer_hash)).to eq(expected_dest_concs)
  end
end

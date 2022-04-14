# frozen_string_literal: true

RSpec.shared_examples 'it only allows creation from tubes' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be true }
      end

      context 'with a plate' do
        let(:parent) { create :v2_plate }
        it { is_expected.to be false }
      end
    end
  end
end

RSpec.shared_examples 'it has a custom page' do |custom_page|
  it 'has a page' do
    expect(described_class.page).to eq custom_page
  end
  it 'renders the page' do
    expect(subject.page).to eq(custom_page)
  end
  it 'can be created' do
    expect(subject).to be_a described_class
  end
  it 'returns a CustomCreatorButton' do
    expect(described_class.creator_button({})).to be_a LabwareCreators::CustomCreatorButton
  end
end

RSpec.shared_examples 'it has no custom page' do |_custom_page|
  it 'renders the default new template' do
    expect(described_class.page).to eq('new')
  end
  it 'can be created' do
    expect(subject).to be_a described_class
  end
  it 'returns a CreatorButton' do
    expect(described_class.creator_button({})).to be_a LabwareCreators::CreatorButton
  end
end

RSpec.shared_examples 'it only allows creation from plates' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be false }
      end

      context 'with a plate' do
        let(:parent) { build :plate }
        it { is_expected.to be true }
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from tagged plates' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be false }
      end

      context 'with a plate' do
        let(:parent) { build :plate }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        context 'which is untagged' do
          let(:tagged) { false }
          it { is_expected.to be false }
        end

        context 'which is tagged' do
          let(:tagged) { true }
          it { is_expected.to be true }
        end
      end
    end
  end
end

RSpec.shared_examples 'it does not allow creation' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be false }
      end

      context 'with a plate' do
        let(:parent) { build :plate }
        before { allow(parent).to receive(:tagged?).and_return(tagged) }

        context 'which is untagged' do
          let(:tagged) { false }
          it { is_expected.to be false }
        end

        context 'which is tagged' do
          let(:tagged) { true }
          it { is_expected.to be false }
        end
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from charged and passed plates with defined downstream pools' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be false }
      end

      context 'with an unpassed plate' do
        let(:parent) { build :unpassed_plate }
        let(:tagged) { true }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }
        it { is_expected.to be false }
      end

      context 'with a passed plate' do
        let(:parent) { build :passed_plate }
        let(:tagged) { true }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }
        it { is_expected.to be true }
      end

      context 'with a previously passed library and a new repool' do
        let(:parent) { build :plate, pools: pools }
        let(:tagged) { true }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }
        let(:pools) do
          # rubocop:todo Layout/LineLength
          # Taken from actual problem plate. Minor modifications for avoiding uuids, and removing bait libraries because they are irrelevant
          # rubocop:enable Layout/LineLength
          {
            'pool-we-want-to-use-1' => {
              'wells' => %w[B3 C9 H10],
              'pool_complete' => false,
              'request_type' => 'limber_multiplexing',
              'for_multiplexing' => true
            },
            'pool-we-want-to-use-2' => {
              'wells' => %w[C3 H5],
              'pool_complete' => false,
              'request_type' => 'limber_multiplexing',
              'for_multiplexing' => true
            },
            'older-complete-pool-1' => {
              'wells' => %w[A5 A7 A10 B5 C9 E6 E11 F5 G5 G8 G10 H3 H10 H11],
              'pool_complete' => true,
              'insert_size' => {
                'from' => 100,
                'to' => 400
              },
              'library_type' => {
                'name' => 'Agilent Pulldown'
              },
              'request_type' => 'limber_reisc'
            },
            'older-complete-pool-2' => {
              'wells' => %w[A3 A6 B3 B7 C5 C12 D6 F6 F8 G2 G6 G7 G9 H5],
              'pool_complete' => true,
              'insert_size' => {
                'from' => 100,
                'to' => 400
              },
              'library_type' => {
                'name' => 'Agilent Pulldown'
              },
              'request_type' => 'limber_reisc'
            }
          }
        end
        it { is_expected.to be true }
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from charged and passed plates' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be false }
      end

      context 'with an unpassed plate' do
        let(:parent) { build :unpassed_plate }
        let(:tagged) { true }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }
        it { is_expected.to be false }
      end

      context 'with a passed plate' do
        let(:parent) { build :passed_plate }
        let(:tagged) { true }
        before { expect(parent).to receive(:tagged?).and_return(tagged) }
        it { is_expected.to be true }
      end
    end
  end
end

RSpec.shared_examples 'a partial stamped plate creator' do
  describe '#save!' do
    let!(:plate_creation_request) do
      stub_api_post(
        'plate_creations',
        payload: {
          plate_creation: {
            parent: parent_uuid,
            child_purpose: child_purpose_uuid,
            user: user_uuid
          }
        },
        body: json(:plate_creation)
      )
    end

    let!(:transfer_creation_request) do
      stub_api_post(
        'transfer_request_collections',
        payload: {
          transfer_request_collection: {
            user: user_uuid,
            transfer_requests: transfer_requests
          }
        },
        body: '{}'
      )
    end

    it 'makes the expected requests' do
      # NB. qc assay post is done using v2 Api, whereas plate creation and transfers posts are using v1 Api
      expect(Sequencescape::Api::V2::QcAssay).to receive(:create)
        .with(qc_results: dest_well_qc_attributes)
        .and_return(true)
      expect(subject.save!).to eq true
      expect(plate_creation_request).to have_been_made
      expect(transfer_creation_request).to have_been_made
    end
  end
end

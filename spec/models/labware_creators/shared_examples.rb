# frozen_string_literal: true

RSpec.shared_examples 'it only allows creation from tubes' do
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'allows creation' do
          expect(is_creatable_from).to be true
        end
      end

      context 'from a plate' do
        let(:parent) { create :v2_plate }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
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
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'from a plate' do
        let(:parent) { build :v2_plate }

        it 'allows creation' do
          expect(is_creatable_from).to be true
        end
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from tagged plates' do
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'from a plate' do
        let(:parent) { build :v2_plate }

        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        context 'which is untagged' do
          let(:tagged) { false }

          it 'disallows creation' do
            expect(is_creatable_from).to be false
          end
        end

        context 'which is tagged' do
          let(:tagged) { true }

          it 'allows creation' do
            expect(is_creatable_from).to be true
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'it does not allow creation' do
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'from a plate' do
        let(:parent) { build :v2_plate }

        before { allow(parent).to receive(:tagged?).and_return(tagged) }

        context 'which is untagged' do
          let(:tagged) { false }

          it 'disallows creation' do
            expect(is_creatable_from).to be false
          end
        end

        context 'which is tagged' do
          let(:tagged) { true }

          it 'disallows creation' do
            expect(is_creatable_from).to be false
          end
        end
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from charged and passed plates with defined downstream pools' do
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'with an unpassed plate' do
        let(:parent) { build :unpassed_plate }
        let(:tagged) { true }

        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'from a passed plate' do
        let(:parent) { build :passed_plate }
        let(:tagged) { true }

        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        it 'allows creation' do
          expect(is_creatable_from).to be true
        end
      end
    end
  end
end

RSpec.shared_examples 'it only allows creation from charged and passed plates' do
  context 'in pre-creation' do
    describe '#creatable_from?' do
      let(:is_creatable_from) { described_class.creatable_from?(parent) }

      context 'from a tube' do
        let(:parent) { build :v2_tube }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'with an unpassed plate' do
        let(:parent) { build :unpassed_plate }
        let(:tagged) { true }

        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        it 'disallows creation' do
          expect(is_creatable_from).to be false
        end
      end

      context 'from a passed plate' do
        let(:parent) { build :passed_plate }
        let(:tagged) { true }

        before { expect(parent).to receive(:tagged?).and_return(tagged) }

        it 'allows creation' do
          expect(is_creatable_from).to be true
        end
      end
    end
  end
end

RSpec.shared_examples 'a QC assaying plate creator' do
  describe '#save!' do
    let(:plate_creations_attributes) { [{ child_purpose_uuid:, parent_uuid:, user_uuid: }] }

    it 'makes the expected requests' do
      # NB. QcAssay and TransferRequestCollection creations are using API v2;
      #     PlateCreation post is using API v1
      expect_api_v2_posts('QcAssay', [{ qc_results: dest_well_qc_attributes }])
      expect_plate_creation
      expect_transfer_request_collection_creation

      expect(subject.save!).to be true
    end
  end
end

shared_examples 'it only allows creation from tubes' do
  context 'pre creation' do
    has_a_working_api

    describe '#support_parent?' do
      subject { described_class.support_parent?(parent) }

      context 'with a tube' do
        let(:parent) { build :tube }
        it { is_expected.to be true }
      end

      context 'with a plate' do
        let(:parent) { build :plate }
        it { is_expected.to be false }
      end
    end
  end
end

shared_examples 'it only allows creation from plates' do
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

shared_examples 'it only allows creation from tagged plates' do
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

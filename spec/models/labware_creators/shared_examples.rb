# frozen_string_literal: true

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

shared_examples 'it has a custom page' do |custom_page|
  it 'has a page' do
    expect(described_class.page).to eq custom_page
  end
  it 'renders the page' do
    controller = CreationController.new
    expect(controller).to receive(:render).with(custom_page)
    subject.render(controller)
  end
  it 'can be created' do
    expect(subject).to be_a described_class
  end
end

shared_examples 'it has no custom page' do |_custom_page|
  it 'saves and redirects' do
    controller = CreationController.new
    expect(controller).to receive(:redirect_to_creator_child).with(subject)
    # We have LOTS of different behaviour on save, which we'll test separately.
    expect(subject).to receive(:save!).and_return(true)
    subject.render(controller)
  end
  it 'can be created' do
    expect(subject).to be_a described_class
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

shared_examples 'it only allows creation from charged and passed plates with defined downstream pools' do
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

shared_examples 'it only allows creation from charged and passed plates' do
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

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Presenters::Presenter, type: :model do
  # Presenter is a module so we need a dummy class
  let(:dummy_class) { Class.new { include Presenters::Presenter } }

  let(:presenter) { dummy_class.new }

  describe '#show_pooling_tab?' do
    context 'when pooling_tab in the presenter has a value' do
      before { presenter.pooling_tab = 'some_value' }

      it 'returns true' do
        expect(presenter.show_pooling_tab?).to be true
      end
    end

    context 'when pooling_tab in the presenter has no value' do
      before { presenter.pooling_tab = '' }

      it 'returns false' do
        expect(presenter.show_pooling_tab?).to be false
      end
    end
  end
end

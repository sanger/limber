# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ViteInlineSvgFileLoader do
  let(:path) { '/images/test.svg' }

  describe '.named' do
    let(:manifest) { instance_double(ViteRuby::Manifest) }
    let(:vite_instance) { instance_double(ViteRuby) }
    let(:vite_asset_path) { '/app/frontend/images/test.svg' }

    before do
      allow(ViteRuby).to receive(:instance).and_return(vite_instance)
      allow(vite_instance).to receive(:manifest).and_return(manifest)
      allow(manifest).to receive(:path_for).with(path).and_return(vite_asset_path)
    end

    context 'when Vite dev server is running' do
      before do
        allow(vite_instance).to receive(:dev_server_running?).and_return(true)
        allow(described_class).to receive(:fetch_from_dev_server).and_return(:svg_content)
      end

      it 'fetches SVG content from the dev server' do
        expect(described_class.named(path)).to eq(:svg_content)
      end
    end

    context 'when Vite dev server is not running' do
      let(:vite_asset_path) { '/app/frontend/images/test.svg' }
      let(:svg_content) { '<svg>From file system</svg>' }

      before do
        allow(vite_instance).to receive(:dev_server_running?).and_return(false)
        allow(manifest).to receive(:path_for).with(path).and_return(vite_asset_path)
        allow(File).to receive(:read).and_return(svg_content)
      end

      it 'reads SVG content from the file system' do
        expect(described_class.named(path)).to eq(svg_content)
      end
    end
  end

  describe '.fetch_from_dev_server', :private do
    let(:svg_content) { '<svg>From dev server</svg>' }

    before { stub_request(:get, "http://localhost:3037#{path}").to_return(status: 200, body: svg_content) }

    it 'fetches SVG content from the dev server' do
      expect(described_class.send(:fetch_from_dev_server, path)).to eq(svg_content)
    end

    context 'when response is not successful' do
      before { stub_request(:get, "http://localhost:3037#{path}").to_return(status: 404) }

      it 'raises an error' do
        expect { described_class.send(:fetch_from_dev_server, path) }.to raise_error(RuntimeError)
      end
    end
  end
end

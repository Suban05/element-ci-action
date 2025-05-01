# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Element::CI do
  context 'with simple config' do
    let(:config) { fake_config('simple_config.yml') }

    it 'runs the CI pipeline' do
      ci = described_class.new(config)
      expect(ci.run).to eq(0)
    end
  end
end

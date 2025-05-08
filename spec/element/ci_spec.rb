# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Element::CI do
  subject(:ci) { described_class.new(config) }

  context 'when simple config' do
    let(:config) { fake_config('simple_config.yml') }

    it 'runs the CI pipeline' do
      expect(ci.run).to eq(0)
    end
  end

  context 'when config with actions' do
    let(:config) { fake_config('config_with_action.yml') }

    it 'runs the CI pipeline' do
      VCR.use_cassette('tests-action-success') do
        expect(ci.run).to eq(0)
      end
    end
  end

  context 'when action has any error' do
    let(:config) { fake_config('unsupported_action_runner_config.yml') }

    it 'throws an exception' do
      VCR.use_cassette('tests-action-success') do
        expect { ci.run }.to raise_error(RuntimeError)
      end
    end
  end

  context 'when project has any error' do
    let(:config) { fake_config('config_project_with_errors.yml') }

    it 'throws an exception' do
      VCR.use_cassette('tests-action-success') do
        expect { ci.run }.to raise_error(RuntimeError)
      end
    end
  end

  context 'when ci runs on pr' do
    let(:config) { fake_config('config_pr.yml') }

    it 'uses head_ref' do
      expect(ci.run).to eq(0)
      expect(ci.instance_variable_get(:@branch)).to eq('feature/branch')
    end
  end

  context 'when ci runs without pr' do
    let(:config) { fake_config('simple_config.yml') }

    it 'uses branch' do
      expect(ci.run).to eq(0)
      expect(ci.instance_variable_get(:@branch)).to eq('main')
    end
  end
end

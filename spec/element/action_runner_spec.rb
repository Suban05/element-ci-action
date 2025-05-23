# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Element::ActionRunner do
  let(:runner) do
    described_class.new(
      config['actions'],
      'https://test-server.com/applications/test-app',
      Logger.new($stdout)
    )
  end

  context 'with actions' do
    let(:config) { fake_config('config_with_action.yml') }

    it 'executes actions' do
      VCR.use_cassette('tests-action-success') do
        expect(runner.run).to eq(0)
      end
    end

    context 'when request returns an error' do
      it 'returns 1' do
        VCR.use_cassette('tests-action-failure-request') do
          expect(runner.run).to eq(1)
        end
      end
    end

    context 'when action is failed' do
      it 'returns 1' do
        VCR.use_cassette('tests-action-failure') do
          expect(runner.run).to eq(1)
        end
      end
    end
  end

  context 'with empty actions' do
    let(:config) { fake_config('simple_config.yml') }

    it 'executes actions' do
      expect(runner.run).to eq(0)
    end
  end

  context 'with unsupported action' do
    let(:config) { fake_config('unsupported_action_runner_config.yml') }

    it 'throws an exception' do
      VCR.use_cassette('tests-action-success') do
        expect { runner.run }.to raise_error(RuntimeError, 'Unsupported method: delete')
      end
    end
  end

  context 'with many actions' do
    let(:config) { fake_config('action_runner_actions_config.yml') }

    it 'processes all actions' do
      VCR.use_cassette('tests-action-success') do
        expect(runner.run).to eq(0)
      end
    end
  end
end

# frozen_string_literal: true

require 'simplecov'

SimpleCov.start do
  add_filter '/spec/'
end

require 'webmock/rspec'
require_relative '../lib/element'
require 'vcr'

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  WebMock.allow_net_connect!

  WebMock::API.prepend(Module.new do
    extend self

    # disable VCR when a WebMock stub is created
    # for clearer spec failure messaging
    def stub_request(*args)
      VCR.turn_off!
      super
    end
  end)

  config.before { VCR.turn_on! }
end

def fake_config(name)
  YAML.load_file(File.join(__dir__, 'fixtures', name))
end

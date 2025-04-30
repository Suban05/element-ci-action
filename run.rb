# frozen_string_literal: true

require_relative 'lib/element/ci'
require 'yaml'

config_path = ARGV[0] || 'config.yml'
abort "File #{config_path} is not found" unless File.exist?(config_path)

Element::CI.new(YAML.load_file(config_path)).run

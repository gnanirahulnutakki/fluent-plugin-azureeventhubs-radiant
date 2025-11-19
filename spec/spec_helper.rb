# frozen_string_literal: true

require "simplecov"

if ENV["COVERAGE"]
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "rspec"

lib_path = File.expand_path("../lib", __dir__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)

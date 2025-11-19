# frozen_string_literal: true

require_relative "lib/fluent/plugin/azureeventhubs_radiant/version"

Gem::Specification.new do |spec|
  spec.name        = "fluent-plugin-azureeventhubs-radiant"
  spec.version     = Fluent::Plugin::AzureEventHubsRadiant::VERSION
  spec.authors     = ["G. Rahul Nutakki"]
  spec.email       = ["gnanirn@gmail.com"]

  spec.summary     = "Modernized Fluentd output plugin for Azure Event Hubs"
  spec.description = "A modernized and actively maintained Fluentd output plugin for Azure Event Hubs " \
                     "with Ruby 3.x and Fluentd 1.x support. Forked from the original " \
                     "fluent-plugin-azureeventhubs with improved security and error handling."
  spec.homepage    = "https://github.com/gnanirahulnutakki/fluent-plugin-azureeventhubs-radiant"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["source_code_uri"]   = spec.homepage
  spec.metadata["changelog_uri"]     = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"]   = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/blob/main/README.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.glob("lib/**/*") + %w[
    README.md
    LICENSE
    NOTICE
    fluent-plugin-azureeventhubs-radiant.gemspec
    Gemfile
    Rakefile
  ]
  spec.require_paths = ["lib"]

  # Runtime dependencies
  spec.add_dependency "fluentd", ">= 1.16", "< 2.0"
  spec.add_dependency "oj", "~> 3.16"

  # Development dependencies
  spec.add_development_dependency "bundler", ">= 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rubocop", "~> 1.60"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end

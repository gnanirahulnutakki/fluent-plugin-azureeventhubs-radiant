# frozen_string_literal: true

require "spec_helper"
require "fluent/plugin/azureeventhubs_radiant/version"

RSpec.describe Fluent::Plugin::AzureEventHubsRadiant do
  it "defines a VERSION constant" do
    expect(described_class::VERSION).not_to be_nil
  end

  it "uses semantic versioning" do
    expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end

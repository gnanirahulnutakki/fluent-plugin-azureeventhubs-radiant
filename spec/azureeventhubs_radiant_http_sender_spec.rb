# frozen_string_literal: true

require "spec_helper"
require "base64"
require "fluent/plugin/azureeventhubs_radiant/http"

RSpec.describe Fluent::Plugin::AzureEventHubsRadiant::HttpSender do
  let(:raw_key) { "test-key" }
  let(:connection_string) do
    "Endpoint=sb://test-namespace.servicebus.windows.net/;" \
      "SharedAccessKeyName=RootManageSharedAccessKey;" \
      "SharedAccessKey=#{Base64.strict_encode64(raw_key)}"
  end

  let(:sender) do
    described_class.new(
      connection_string: connection_string,
      hub_name: "test-hub",
      expiry: 3600,
      proxy_addr: nil,
      proxy_port: 3128,
      open_timeout: 60,
      read_timeout: 60,
      ssl_verify: true,
      coerce_to_utf8: true,
      non_utf8_replacement_string: "?"
    )
  end

  it "builds a SAS token with expected parts" do
    expiry = Time.now.to_i + 3600
    token = sender.send(:build_sas_token, expiry)

    expect(token).to include("SharedAccessSignature")
    expect(token).to include("sr=")
    expect(token).to include("sig=")
    expect(token).to include("se=#{expiry}")
    expect(token).to include("skn=RootManageSharedAccessKey")
  end

  it "encodes payload as JSON and delegates to perform_request" do
    expect(sender).to receive(:perform_request).with(
      kind_of(String),
      hash_including("Content-Type" => a_string_including("application/json"))
    ).and_return(true)

    sender.send_with_properties({"foo" => "bar"}, {"PartitionKey" => "p1", "custom" => "x"})
  end
end

# frozen_string_literal: true

require "spec_helper"
require "fluent/plugin/azureeventhubs_radiant/http"

RSpec.describe "JSON Encoding Resilience" do
  let(:connection_string) do
    "Endpoint=sb://test.servicebus.windows.net/;" \
      "SharedAccessKeyName=test;" \
      "SharedAccessKey=dGVzdA=="
  end

  let(:sender) do
    Fluent::Plugin::AzureEventHubsRadiant::HttpSender.new(
      connection_string: connection_string,
      hub_name: "test-hub",
      ssl_verify: false,
      coerce_to_utf8: true
    )
  end

  describe "#encode_payload" do
    it "encodes simple hash correctly" do
      payload = { "message" => "test log", "level" => "INFO" }
      result = sender.send(:encode_payload, payload)

      expect(result).to be_a(String)
      parsed = Oj.load(result)
      expect(parsed["message"]).to eq("test log")
      expect(parsed["level"]).to eq("INFO")
    end

    it "handles arrays correctly" do
      payload = { "records" => [{ "log" => "entry1" }, { "log" => "entry2" }] }
      result = sender.send(:encode_payload, payload)

      parsed = Oj.load(result)
      expect(parsed["records"]).to be_an(Array)
      expect(parsed["records"].length).to eq(2)
    end

    it "handles nested structures" do
      payload = {
        "kubernetes" => {
          "pod_name" => "test-pod",
          "namespace" => "default"
        },
        "message" => "application log"
      }

      result = sender.send(:encode_payload, payload)
      parsed = Oj.load(result)

      expect(parsed["kubernetes"]["pod_name"]).to eq("test-pod")
    end

    it "handles numeric values" do
      payload = {
        "count" => 42,
        "pi" => 3.14159,
        "timestamp" => 1234567890
      }

      result = sender.send(:encode_payload, payload)
      parsed = Oj.load(result)

      expect(parsed["count"]).to eq(42)
      expect(parsed["pi"]).to be_within(0.0001).of(3.14159)
    end

    it "handles boolean values" do
      payload = {
        "success" => true,
        "failed" => false
      }

      result = sender.send(:encode_payload, payload)
      parsed = Oj.load(result)

      expect(parsed["success"]).to eq(true)
      expect(parsed["failed"]).to eq(false)
    end

    it "handles nil values" do
      payload = {
        "message" => "test",
        "optional_field" => nil
      }

      result = sender.send(:encode_payload, payload)
      parsed = Oj.load(result)

      expect(parsed["optional_field"]).to be_nil
    end
  end

  describe "UTF-8 handling" do
    it "coerces invalid UTF-8 to valid UTF-8" do
      payload = {
        "message" => "test\xFF\xFElog"  # Invalid UTF-8 bytes
      }

      result = sender.send(:encode_payload, payload)
      expect(result).to be_a(String)
      expect(result.encoding).to eq(Encoding::UTF_8)
      expect(result.valid_encoding?).to eq(true)
    end

    it "handles mixed encoding in nested structures" do
      payload = {
        "logs" => [
          { "message" => "valid utf-8" },
          { "message" => "invalid\xFFbytes" }
        ]
      }

      result = sender.send(:encode_payload, payload)
      expect(result.valid_encoding?).to eq(true)
    end
  end
end

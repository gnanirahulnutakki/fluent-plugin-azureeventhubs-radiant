# frozen_string_literal: true

require "spec_helper"
require "fluent/test"
require "fluent/test/driver/output"
require "fluent/plugin/out_azureeventhubs_radiant"

RSpec.describe Fluent::Plugin::AzureEventHubsRadiantOutput do
  let(:config) do
    %(
      connection_string Endpoint=sb://test.servicebus.windows.net/;SharedAccessKeyName=test;SharedAccessKey=dGVzdA==
      hub_name test-hub
    )
  end

  let(:driver) { Fluent::Test::Driver::Output.new(described_class).configure(config) }

  describe "configuration" do
    it "registers as 'azureeventhubs'" do
      expect(Fluent::Plugin.lookup_output("azureeventhubs")).to eq(described_class)
    end

    it "registers as 'azureeventhubs_buffered' for backward compatibility" do
      expect(Fluent::Plugin.lookup_output("azureeventhubs_buffered")).to eq(described_class)
    end

    it "configures with minimal configuration" do
      expect(driver.instance.hub_name).to eq("test-hub")
    end

    it "defaults include_tag to false" do
      expect(driver.instance.include_tag).to eq(false)
    end

    it "defaults include_time to false" do
      expect(driver.instance.include_time).to eq(false)
    end

    it "defaults ssl_verify to true" do
      expect(driver.instance.ssl_verify).to eq(true)
    end

    it "defaults coerce_to_utf8 to true" do
      expect(driver.instance.coerce_to_utf8).to eq(true)
    end

    it "raises error if type is not https" do
      config_with_amqps = config + "\ntype amqps"
      expect do
        Fluent::Test::Driver::Output.new(described_class).configure(config_with_amqps)
      end.to raise_error(Fluent::ConfigError, /Only type 'https' is supported/)
    end
  end

  describe "#format" do
    it "formats records to msgpack" do
      time = Fluent::EventTime.now
      record = { "message" => "test log" }
      formatted = driver.instance.format("test.tag", time, record)

      expect(formatted).to be_a(String)
      unpacked = MessagePack.unpack(formatted)
      expect(unpacked).to be_a(Array)
      expect(unpacked[0]).to eq("test.tag")
      expect(unpacked[2]).to include("message" => "test log")
    end
  end

  describe "#write with include_tag and include_time" do
    let(:config_with_enrichment) do
      config + %(
        include_tag true
        include_time true
        tag_time_name timestamp
      )
    end

    let(:driver_enriched) do
      Fluent::Test::Driver::Output.new(described_class).configure(config_with_enrichment)
    end

    it "includes tag and time in record when configured" do
      allow_any_instance_of(Fluent::Plugin::AzureEventHubsRadiant::HttpSender)
        .to receive(:send_with_properties).and_return(true)

      time = Fluent::EventTime.now
      driver_enriched.run(default_tag: "test.tag") do
        driver_enriched.feed(time, { "message" => "test" })
      end

      # Verify the sender was called
      expect(driver_enriched.instance.instance_variable_get(:@sender))
        .to have_received(:send_with_properties)
    end
  end

  describe "UTF-8 coercion" do
    let(:config_with_utf8) do
      config + %(
        coerce_to_utf8 true
        non_utf8_replacement_string ?
      )
    end

    it "handles non-UTF8 strings gracefully" do
      driver_utf8 = Fluent::Test::Driver::Output.new(described_class).configure(config_with_utf8)

      allow_any_instance_of(Fluent::Plugin::AzureEventHubsRadiant::HttpSender)
        .to receive(:send_with_properties).and_return(true)

      time = Fluent::EventTime.now
      driver_utf8.run(default_tag: "test.tag") do
        driver_utf8.feed(time, { "message" => "test\xFFlog" })
      end

      expect(driver_utf8.instance.instance_variable_get(:@sender))
        .to have_received(:send_with_properties)
    end
  end

  describe "batching" do
    let(:config_with_batch) do
      config + %(
        batch true
        max_batch_size 5
      )
    end

    let(:driver_batch) do
      Fluent::Test::Driver::Output.new(described_class).configure(config_with_batch)
    end

    it "batches records when batch mode is enabled" do
      allow_any_instance_of(Fluent::Plugin::AzureEventHubsRadiant::HttpSender)
        .to receive(:send_with_properties).and_return(true)

      time = Fluent::EventTime.now
      driver_batch.run(default_tag: "test.tag") do
        10.times { |i| driver_batch.feed(time, { "message" => "log #{i}" }) }
      end

      # Should be called 2 times (10 logs / batch_size of 5)
      expect(driver_batch.instance.instance_variable_get(:@sender))
        .to have_received(:send_with_properties).at_least(2).times
    end
  end
end

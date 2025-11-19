# frozen_string_literal: true

require "fluent/plugin/output"
require "fluent/plugin/azureeventhubs_radiant/http"

module Fluent
  module Plugin
    # Modernized Azure Event Hubs output plugin.
    #
    # This plugin is API-compatible with the original
    # `fluent-plugin-azureeventhubs` `azureeventhubs_buffered` output,
    # but updated for Ruby 3.x / Fluentd 1.x and safer HTTP handling.
    class AzureEventHubsRadiantOutput < Output
      Fluent::Plugin.register_output("azureeventhubs", self)
      # Backward-compatible type name used by the original plugin
      Fluent::Plugin.register_output("azureeventhubs_buffered", self)

      helpers :compat_parameters, :inject

      DEFAULT_BUFFER_TYPE = "memory".freeze

      config_param :connection_string, :string, secret: true
      config_param :hub_name,          :string
      config_param :include_tag,       :bool,   default: false
      config_param :include_time,      :bool,   default: false
      config_param :tag_time_name,     :string, default: "time"
      config_param :expiry_interval,   :integer, default: 3600
      config_param :type,              :string,  default: "https" # https / amqps (not implemented)
      config_param :proxy_addr,        :string,  default: ""
      config_param :proxy_port,        :integer, default: 3128
      config_param :open_timeout,      :integer, default: 60
      config_param :read_timeout,      :integer, default: 60
      config_param :message_properties,:hash,    default: nil
      config_param :batch,             :bool,    default: false
      config_param :max_batch_size,    :integer, default: 20
      config_param :print_records,     :bool,    default: false
      config_param :ssl_verify,        :bool,    default: true
      config_param :coerce_to_utf8,    :bool,    default: true
      config_param :non_utf8_replacement_string, :string, default: " "

      config_section :buffer do
        config_set_default :@type, DEFAULT_BUFFER_TYPE
        config_set_default :chunk_keys, ["tag"]
      end

      def configure(conf)
        compat_parameters_convert(conf, :buffer, :inject)
        super

        if @type != "https"
          raise Fluent::ConfigError, "Only type 'https' is supported in azureeventhubs_radiant output"
        end

        @sender = Fluent::Plugin::AzureEventHubsRadiant::HttpSender.new(
          connection_string: @connection_string,
          hub_name:          @hub_name,
          expiry:            @expiry_interval,
          proxy_addr:        blank_to_nil(@proxy_addr),
          proxy_port:        @proxy_port,
          open_timeout:      @open_timeout,
          read_timeout:      @read_timeout,
          ssl_verify:        @ssl_verify,
          coerce_to_utf8:    @coerce_to_utf8,
          non_utf8_replacement_string: @non_utf8_replacement_string
        )

        raise Fluent::ConfigError, "'tag' in chunk_keys is required." unless @chunk_key_tag
      end

      def format(tag, time, record)
        record = inject_values_to_record(tag, time, record)
        [tag, time, record].to_msgpack
      end

      def formatted_to_msgpack_binary?
        true
      end

      def write(chunk)
        if @batch
          write_batched(chunk)
        else
          write_singularly(chunk)
        end
      end

      private

      def write_singularly(chunk)
        chunk.msgpack_each do |tag, time, record|
          log.debug { "azureeventhubs: sending single record" }
          log_record(tag, record) if @print_records
          enrich_record(tag, time, record)
          @sender.send_with_properties(record, @message_properties)
        end
      end

      def write_batched(chunk)
        records = []

        chunk.msgpack_each do |tag, time, record|
          log.debug { "azureeventhubs: queueing record for batch" }
          log_record(tag, record) if @print_records
          enrich_record(tag, time, record)
          records << record
        end

        records.each_slice(@max_batch_size) do |group|
          payload = { "records" => group }
          @sender.send_with_properties(payload, @message_properties)
        end
      end

      def enrich_record(tag, time, record)
        record["tag"] = tag if @include_tag
        record[@tag_time_name] = time if @include_time
      end

      def log_record(tag, record)
        log.info "azureeventhubs(tag=#{tag}): #{record}"
      end

      def blank_to_nil(value)
        value.nil? || value.empty? ? nil : value
      end
    end
  end
end

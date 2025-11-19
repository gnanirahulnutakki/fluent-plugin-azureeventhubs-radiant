# frozen_string_literal: true

require "net/http"
require "uri"
require "openssl"
require "oj"
require "base64"
require "cgi"
require "time"

module Fluent
  module Plugin
    module AzureEventHubsRadiant
      class HttpError < StandardError
        attr_reader :response

        def initialize(message, response = nil)
          super(message)
          @response = response
        end
      end

      # HTTPS Event Hubs sender used by the output plugin.
      class HttpSender
        DEFAULT_EXPIRY       = 3600
        DEFAULT_PROXY_PORT   = 3128
        DEFAULT_OPEN_TIMEOUT = 60
        DEFAULT_READ_TIMEOUT = 60

        def initialize(connection_string:, hub_name:, expiry: DEFAULT_EXPIRY,
                       proxy_addr: nil, proxy_port: DEFAULT_PROXY_PORT,
                       open_timeout: DEFAULT_OPEN_TIMEOUT,
                       read_timeout: DEFAULT_READ_TIMEOUT,
                       ssl_verify: true,
                       coerce_to_utf8: true,
                       non_utf8_replacement_string: " ")
          @hub_name          = hub_name
          @expiry_interval   = expiry.to_i
          @proxy_addr        = proxy_addr
          @proxy_port        = proxy_port
          @open_timeout      = open_timeout
          @read_timeout      = read_timeout
          @ssl_verify        = ssl_verify
          @coerce_to_utf8    = coerce_to_utf8
          @utf8_replacement  = non_utf8_replacement_string

          parse_connection_string(connection_string)
          build_uri

          @sas_token = nil
          @sas_token_expiry = nil
        end

        # Convenience method (kept, but not named `send` to avoid clobbering Object#send)
        def send_payload(payload)
          send_with_properties(payload, nil)
        end

        # Public API used by the Fluentd output plugin.
        def send_with_properties(payload, message_properties)
          body = encode_payload(payload)
          headers = default_headers

          if message_properties && !message_properties.empty?
            broker_props = {}
            custom_props = {}

            message_properties.each do |key, value|
              case key.to_s
              when "PartitionKey", "partition_key", "partitionKey"
                broker_props["PartitionKey"] = value
              else
                custom_props[key.to_s] = value
              end
            end

            headers["BrokerProperties"] = Oj.dump(broker_props, mode: :compat) unless broker_props.empty?
            headers["Properties"] = Oj.dump(custom_props, mode: :compat) unless custom_props.empty?
          end

          perform_request(body, headers)
        end

        private

        def parse_connection_string(connection_string)
          parts = connection_string.split(";").map { |item| item.split("=", 2) }.to_h

          endpoint = parts["Endpoint"] or raise ArgumentError, "Endpoint is missing from connection string"
          @sas_key_name = parts["SharedAccessKeyName"] or raise ArgumentError, "SharedAccessKeyName is missing"
          @sas_key_value = parts["SharedAccessKey"] or raise ArgumentError, "SharedAccessKey is missing"

          @endpoint_host = endpoint.sub(%r{^sb://}, "").sub(%r{/$}, "")
        end

        def build_uri
          @uri = URI.parse("https://#{@endpoint_host}/#{@hub_name}/messages")
        end

        def default_headers
          {
            "Content-Type" => "application/json; charset=utf-8",
            "Authorization" => current_sas_token
          }
        end

        def current_sas_token
          now = Time.now.to_i
          if @sas_token.nil? || @sas_token_expiry.nil? || now >= @sas_token_expiry - 60
            @sas_token_expiry = now + @expiry_interval
            @sas_token = build_sas_token(@sas_token_expiry)
          end
          @sas_token
        end

        def build_sas_token(expiry)
          resource = @uri.to_s.downcase
          encoded_resource = CGI.escape(resource)
          string_to_sign = "#{encoded_resource}\n#{expiry}"

          signature = OpenSSL::HMAC.digest("sha256", @sas_key_value, string_to_sign)
          encoded_signature = CGI.escape(Base64.strict_encode64(signature))

          "SharedAccessSignature sr=#{encoded_resource}&sig=#{encoded_signature}&se=#{expiry}&skn=#{@sas_key_name}"
        end

        # Encode payload to JSON.
        #
        # Uses Oj in compat mode for better performance and more lenient handling
        # of various Ruby objects compared to the standard JSON library.
        # This helps avoid JSON encoding errors with complex log structures.
        def encode_payload(payload)
          obj = @coerce_to_utf8 ? deep_coerce_to_utf8(payload) : payload
          Oj.dump(obj, mode: :compat)
        rescue Oj::Error => e
          # Fallback: attempt to stringify if JSON encoding fails
          # This handles edge cases where the payload contains non-JSON-serializable objects
          Oj.dump({ "message" => obj.to_s, "error" => "JSON encoding failed: #{e.message}" }, mode: :compat)
        end

        def deep_coerce_to_utf8(obj)
          case obj
          when String
            return obj if obj.encoding == Encoding::UTF_8 && obj.valid_encoding?

            obj.encode(
              Encoding::UTF_8,
              invalid: :replace,
              undef: :replace,
              replace: @utf8_replacement
            )
          when Array
            obj.map { |v| deep_coerce_to_utf8(v) }
          when Hash
            obj.each_with_object({}) do |(k, v), acc|
              acc[deep_coerce_to_utf8(k)] = deep_coerce_to_utf8(v)
            end
          else
            obj
          end
        end

        def perform_request(body, headers)
          http = if @proxy_addr && !@proxy_addr.empty?
                   Net::HTTP.new(@uri.host, @uri.port, @proxy_addr, @proxy_port)
                 else
                   Net::HTTP.new(@uri.host, @uri.port)
                 end

          http.use_ssl = true
          http.open_timeout = @open_timeout
          http.read_timeout = @read_timeout
          http.verify_mode = @ssl_verify ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

          request = Net::HTTP::Post.new(@uri.request_uri)
          headers.each { |k, v| request[k] = v }
          request.body = body

          response = http.request(request)

          unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
            raise HttpError.new("Azure Event Hubs HTTP request failed with status #{response.code}", response)
          end

          true
        rescue StandardError => e
          raise HttpError.new("Azure Event Hubs HTTP request failed: #{e.message}")
        end
      end
    end
  end
end

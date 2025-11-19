# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-19

### Added
- Initial release of modernized Azure Event Hubs Fluentd plugin
- Ruby 3.0+ support (dropped Ruby 2.x)
- Modern Fluentd 1.16+ compatibility
- Proper module namespacing (`Fluent::Plugin::AzureEventHubsRadiant`)
- Enhanced SSL/TLS configuration:
  - Configurable `ssl_verify` parameter (default: true)
  - TLS certificate verification control
- UTF-8 encoding safety:
  - `coerce_to_utf8` parameter for automatic UTF-8 conversion
  - `non_utf8_replacement_string` parameter for custom replacement characters
  - Deep UTF-8 coercion for nested data structures
- SAS token caching for improved performance
  - Tokens cached and reused until expiry
  - Automatic refresh 60 seconds before expiration
- Improved error handling:
  - Custom `HttpError` exception with response details
  - Better error messages for troubleshooting
- Backward compatibility:
  - Registered as both `azureeventhubs` and `azureeventhubs_buffered`
  - Drop-in replacement for original plugin
- Enhanced message properties handling:
  - Proper separation of broker properties (PartitionKey) and custom properties
  - Support for multiple property name formats (PartitionKey, partition_key, partitionKey)
- Lenient JSON encoding:
  - Uses `oj` (Optimized JSON) instead of standard library `json`
  - Fallback handling for non-JSON-serializable objects
  - Prevents log loss due to encoding errors
- Comprehensive test suite:
  - RSpec tests for HTTP sender
  - JSON encoding resilience tests
  - UTF-8 handling tests
  - Version validation
- Connection string parsing improvements:
  - Robust parsing with validation
  - Clear error messages for missing required fields
- Configuration parameter security:
  - `connection_string` marked as secret (won't be logged)
- Better logging and debugging:
  - Lazy-evaluated debug messages
  - Improved log formatting with tags

### Changed
- Minimum Ruby version requirement: 3.0+
- Minimum Fluentd version: 1.16
- Replaced standard `json` library with `oj` for better performance
- Content-Type header corrected from `application/atom+xml` to `application/json`
- SAS token generation now cached (was generated on every request)
- HTTP sender moved to proper module namespace
- Error handling: no longer silently swallows exceptions
- Class name changed from `AzureEventHubsOutputBuffered` to `AzureEventHubsRadiantOutput`
- Updated to modern Ruby code style with `frozen_string_literal`

### Removed
- Support for Ruby 2.x
- Support for AMQPS protocol (only HTTPS supported)
- Silent error swallowing in HTTP requests

### Fixed
- Incorrect Content-Type header (was `application/atom+xml`, now correctly `application/json`)
- Silent failures in HTTP requests - now properly raises exceptions
- Fragile connection string parsing - now robust with proper validation
- Performance issue with SAS token generation on every request
- Missing error context when requests fail
- Potential encoding issues with non-UTF-8 log data
- JSON encoding failures that could cause log loss

### Security
- Connection strings now marked as secret in configuration
- SSL certificate verification enabled by default
- TLS properly configured with verify mode control

---

## Upstream History

This plugin is a modernized fork of [fluent-plugin-azureeventhubs](https://github.com/htgc/fluent-plugin-azureeventhubs) version 0.0.7.

For upstream changelog history, see: https://github.com/htgc/fluent-plugin-azureeventhubs

---

## Migration from Original Plugin

To migrate from `fluent-plugin-azureeventhubs` to `fluent-plugin-azureeventhubs-radiant`:

1. **Update your Gemfile**:
   ```ruby
   # Old
   # gem "fluent-plugin-azureeventhubs"

   # New
   gem "fluent-plugin-azureeventhubs-radiant"
   ```

2. **Verify Ruby version**: Ensure you're running Ruby 3.0 or newer

3. **Configuration is backward compatible**: Existing configurations using `@type azureeventhubs_buffered` will continue to work

### Breaking Changes
- Ruby 2.x is no longer supported
- AMQPS protocol support removed (only HTTPS is supported)
- Errors are no longer silently swallowed - may require error handling updates in your deployment

[0.1.0]: https://github.com/gnanirahulnutakki/fluent-plugin-azureeventhubs-radiant/releases/tag/v0.1.0

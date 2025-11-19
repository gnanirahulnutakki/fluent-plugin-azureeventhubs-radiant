# fluent-plugin-azureeventhubs-radiant

Modernized Fluentd output plugin for sending logs to Azure Event Hubs.

This project is a security and compatibility focused fork of the original
[`fluent-plugin-azureeventhubs`](https://github.com/htgc/fluent-plugin-azureeventhubs)
plugin, updated for:

- Ruby 3.x
- Fluentd 1.x
- Safer TLS handling and better error reporting when talking to Azure Event Hubs.

## Status

This is an early radiant version intended for experimentation. The API is kept
as close as reasonable to the original `azureeventhubs_buffered` output.

## Installation

```bash
gem install fluent-plugin-azureeventhubs-radiant
```

## Basic configuration

```xml
<match **>
  @type azureeventhubs
  connection_string "Endpoint=sb://...;SharedAccessKeyName=...;SharedAccessKey=..."
  hub_name "my-event-hub"

  # Optional
  include_tag  true
  include_time true
  tag_time_name time
  batch true
  max_batch_size 20
  ssl_verify true
</match>
```

## Example Configurations

See the [`examples/`](examples/) directory for complete configuration examples:

- [`basic.conf`](examples/basic.conf) - Minimal configuration to get started
- [`with-metadata.conf`](examples/with-metadata.conf) - Include Fluentd tag and timestamp
- [`batch-mode.conf`](examples/batch-mode.conf) - Batch multiple records for better throughput
- [`kubernetes.conf`](examples/kubernetes.conf) - Optimized for Kubernetes cluster logs
- [`ssl-configuration.conf`](examples/ssl-configuration.conf) - Custom SSL/TLS settings
- [`proxy-configuration.conf`](examples/proxy-configuration.conf) - HTTP proxy support
- [`advanced.conf`](examples/advanced.conf) - Production-ready configuration with all features

## License

MIT, same as the original plugin.

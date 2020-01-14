require 'rack'
require "sma_exporter"
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

configFile = File.join(
    File.dirname(ENV.fetch('SMA_SBFPATH')),
    'SBFspot.cfg'
)
data = File.binread(configFile)

if ENV['SMA_ADDRESS']
	data[/IP_Address=(.+)$/, 1] = ENV['SMA_ADDRESS']
end
if ENV['SMA_PASSWORD']
    data[/Password=(.+)$/, 1] = ENV['SMA_PASSWORD']
end
if ENV['TZ']
    data[/Timezone=(.+)$/, 1] = ENV['TZ']
end

File.binwrite(configFile, data)

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use SmaExporter::Rack
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

SmaExporter::Runner.register!

run ->(_) { 
  [200, { 'Content-Type' => 'text/html' }, ['OK'] ] 
}

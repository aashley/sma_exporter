require 'rack'
require "sma_exporter"
require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

configFile = File.join(
    File.dirname(ENV.fetch('SMA_SBFPATH')),
    'SBFspot.cfg'
)

if ENV['SMA_ADDRESS']
	data = File.binread(configFile)
	data[/IP_Address=(.+)$/, 1] = ENV['SMA_ADDRESS']
	File.binwrite(configFile, data)
end

if ENV['SMA_PASSWORD']
    data = File.binread(configFile)
    data[/Password=(.+)$/, 1] = ENV['SMA_PASSWORD']
    File.binwrite(configFile, data)
end

use Rack::Deflater, if: ->(_, _, _, body) { body.any? && body[0].length > 512 }
use SmaExporter::Rack
use Prometheus::Middleware::Collector
use Prometheus::Middleware::Exporter

SmaExporter::Runner.register!

run ->(_) { 
  [200, { 'Content-Type' => 'text/html' }, ['OK'] ] 
}

#!/usr/bin/env ruby

require 'net/http'
require 'yaml'
require 'aws-sdk-sns'

# AWS credentials
creds = YAML.load_file 'aws.yml'
Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(creds['access_key'], creds['secret_key'])
})

# fetch rates file
config = YAML.load_file 'config.yml'

uri = URI(config['rate_source'])
res = Net::HTTP.get_response(uri)

if res.is_a?(Net::HTTPSuccess)
  rate   = ""
  points = ""
  apr    = ""

  lines = res.body.split("\n")
  lines.each do |line|
    line.strip!
    if line =~ /#{config['mortgage']}/
      rate   = line.match(/(\d.\d{3})/)[0] if line =~ /interest/
      points = line.match(/(\d.\d{3})/)[0] if line =~ /points/
      apr    = line.match(/(\d.\d{3})/)[0] if line =~ /apr/
    end
  end

  today     = Date.today
  sixty_out = today + 60
  message   = "#{today}\rRate: #{rate} / Points: #{points} / APR: #{apr}\rUntil #{sixty_out}\r#{config['mortgage_number']}\r#{config['aid']}"

  # text message
  client = Aws::SNS::Client.new
  resp   = client.publish({phone_number: config['phone_number'], message: message})
else
  puts 'failed'
end

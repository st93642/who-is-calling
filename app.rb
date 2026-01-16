require 'sinatra'
require 'redis'
require 'dotenv'
require 'json'

# Load environment variables from .env file
Dotenv.load

# Global Redis connection
$redis = nil

def redis
  return $redis if $redis
  
  if ENV['REDIS_URL']
    $redis = Redis.new(url: ENV['REDIS_URL'])
  else
    $redis = Redis.new
  end
end

# Phone number normalization for Latvian numbers
# Converts local (22811907) or international (+37122811907) to normalized format (37122811907)
def normalize_phone(number)
  raise ArgumentError, 'Phone number cannot be empty' if number.nil? || number.to_s.strip.empty?
  
  # Remove all non-digit characters
  cleaned = number.to_s.gsub(/\D/, '')
  
  # Validate: must be 8 digits (local) or 11 digits (international with country code)
  raise ArgumentError, 'Invalid phone number format' unless cleaned.length == 8 || cleaned.length == 11
  
  # If 8 digits, prepend Latvian country code 371
  if cleaned.length == 8
    cleaned = '371' + cleaned
  end
  
  # Validate it starts with 371 (Latvian country code)
  raise ArgumentError, 'Not a valid Latvian phone number' unless cleaned.start_with?('371')
  
  cleaned
end

# Health check endpoint
get '/' do
  'OK'
end

# Search endpoint
get '/search' do
  halt 400, { error: 'Missing number parameter' }.to_json unless params['number']
  
  begin
    normalized = normalize_phone(params['number'])
  rescue ArgumentError => e
    halt 400, { error: e.message }.to_json
  end
  
  urls_json = redis.get(normalized)
  urls = urls_json ? JSON.parse(urls_json) : []
  
  content_type :json
  { results: urls, found: !urls.empty?, normalized_number: normalized }.to_json
end

#!/usr/bin/env ruby

require 'json'
require 'redis'
require 'net/http'
require 'uri'
require 'timeout'
require 'dotenv'

# Load environment variables
Dotenv.load

class LatvianPhoneCrawler
  attr_reader :redis, :websites, :timeout
  
  def initialize
    @redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
    @websites = load_websites
    @timeout = 30
    @total_urls_processed = 0
    @total_numbers_extracted = 0
    @total_unique_numbers = 0
    @failed_urls = []
    
    # Handle Ctrl+C gracefully
    trap('INT') do
      puts "\n\n🛑 Received interrupt signal. Finishing current page and saving results..."
      cleanup
      print_summary
      exit
    end
  end
  
  def run
    puts "🚀 Starting Latvian Government Website Phone Number Crawler"
    puts "=" * 60
    puts "Found #{@websites.length} websites to crawl"
    puts "Redis URL: #{ENV['REDIS_URL'] || 'redis://localhost:6379'}"
    puts "=" * 60
    
    begin
      # Clear previous data if running fresh
      if ENV['CLEAR_REDIS'] == 'true'
        puts "🧹 Clearing previous Redis data..."
        @redis.flushdb
      end
      
      # Crawl each website
      crawl_websites
      
    rescue => e
      puts "❌ Error during crawling: #{e.message}"
      puts e.backtrace.join("\n")
    ensure
      print_summary
    end
  end
  
  private
  
  def load_websites
    if File.exist?('government_websites.json')
      JSON.parse(File.read('government_websites.json'))
    else
      puts "❌ government_websites.json not found!"
      exit 1
    end
  rescue JSON::ParserError => e
    puts "❌ Error parsing government_websites.json: #{e.message}"
    exit 1
  end
  
  def crawl_websites
    @websites.each_with_index do |website, index|
      url = website['url']
      name = website['name']
      
      puts "\n[#{index + 1}/#{@websites.length}] 🌐 Crawling: #{name}"
      puts "    URL: #{url}"
      
      begin
        phone_numbers = crawl_url(url)
        
        if phone_numbers.any?
          store_phone_numbers(phone_numbers, url)
          puts "    ✅ Found #{phone_numbers.length} unique phone number(s)"
          @total_numbers_extracted += phone_numbers.length
        else
          puts "    ℹ️  No phone numbers found"
        end
        
        @total_urls_processed += 1
        
      rescue => e
        puts "    ❌ Error crawling #{url}: #{e.message}"
        @failed_urls << { url: url, error: e.message }
        next
      end
    end
  end
  
  def crawl_url(url)
    begin
      Timeout.timeout(@timeout) do
        uri = URI.parse(url)
        
        # Handle both HTTP and HTTPS
        http_class = uri.scheme == 'https' ? Net::HTTPS : Net::HTTP
        
        response = http_class.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
          http.read_timeout = @timeout
          http.open_timeout = @timeout
          request = Net::HTTP::Get.new(uri.request_uri)
          request['User-Agent'] = 'Mozilla/5.0 (compatible; LatvianPhoneCrawler/1.0)'
          
          http.request(request)
        end
        
        if response.is_a?(Net::HTTPSuccess)
          # Extract phone numbers from HTML content
          extract_phone_numbers(response.body)
        else
          puts "    🔌 HTTP error: #{response.code} #{response.message}"
          []
        end
      end
    rescue Timeout::Error
      puts "    ⏰ Timeout after #{@timeout} seconds"
      []
    rescue => e
      puts "    🔌 Network error: #{e.message}"
      []
    end
  end
  
  def extract_phone_numbers(html_content)
    return [] if html_content.nil? || html_content.empty?
    
    # Find all potential phone numbers in various formats
    phone_patterns = [
      # International with +
      /\+371\s*(\d{8})/i,
      # International with 00371
      /00371\s*(\d{8})/i,
      # Local 8-digit numbers (starting with 2-9)
      /\b([2-9]\d{7})\b/,
      # Numbers with various separators: spaces, dashes, parentheses
      /(\d{2})[\s\-]?(\d{2})[\s\-]?(\d{2})[\s\-]?(\d{2})/,
      # Pattern like (22) 81 19 07
      /\((\d{2})\)\s*(\d{2})\s*(\d{2})\s*(\d{2})/
    ]
    
    found_numbers = []
    
    phone_patterns.each do |pattern|
      matches = html_content.scan(pattern)
      matches.each do |match|
        if match.is_a?(Array)
          # Handle grouped matches
          number = match.join
        else
          number = match
        end
        
        # Normalize to Latvian format (371 + 8 digits)
        normalized = normalize_to_latvian(number)
        found_numbers << normalized if valid_latvian_number?(normalized)
      end
    end
    
    # Remove duplicates and return
    found_numbers.uniq
  end
  
  def normalize_to_latvian(number)
    # Remove all non-digit characters
    digits = number.gsub(/\D/, '')
    
    # Handle different formats
    if digits.start_with?('371')
      digits
    elsif digits.length == 8 && digits[0] =~ /[2-9]/
      "371#{digits}"
    else
      digits
    end
  end
  
  def valid_latvian_number?(number)
    # Valid Latvian number: 371 + 8 digits
    number =~ /^371\d{8}$/
  end
  
  def store_phone_numbers(phone_numbers, url)
    phone_numbers.each do |phone|
      @redis.sadd(phone, url)
    end
  end
  
  def cleanup
    puts "🧹 Cleanup complete"
  end
  
  def print_summary
    puts "\n" + "=" * 60
    puts "📊 CRAWLING SUMMARY"
    puts "=" * 60
    puts "✅ URLs processed: #{@total_urls_processed}/#{@websites.length}"
    puts "📞 Total numbers extracted: #{@total_numbers_extracted}"
    
    # Get unique numbers count from Redis
    if @total_urls_processed > 0
      unique_numbers = @redis.keys('371*').length
      puts "🔢 Unique numbers in Redis: #{unique_numbers}"
      @total_unique_numbers = unique_numbers
    end
    
    if @failed_urls.any?
      puts "❌ Failed URLs: #{@failed_urls.length}"
      @failed_urls.each do |failed|
        puts "   - #{failed[:url]}: #{failed[:error]}"
      end
    end
    
    puts "=" * 60
  end
end

# Main execution
if __FILE__ == $0
  crawler = LatvianPhoneCrawler.new
  crawler.run
end
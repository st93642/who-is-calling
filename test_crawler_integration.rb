require 'minitest/autorun'
require 'json'
require 'webmock'
require 'timeout'
require 'set'
require 'net/http'
require 'uri'

# Include WebMock to stub HTTP requests
WebMock.disable_net_connect!(allow_localhost: true)

# Mock Redis class for testing
class MockRedis
  def initialize
    @data = Hash.new { |h, k| h[k] = Set.new }
  end
  
  def sadd(key, value)
    @data[key] << value
  end
  
  def sismember(key, value)
    @data[key].include?(value)
  end
  
  def scard(key)
    @data[key].size
  end
  
  def keys(pattern)
    @data.keys.grep(/#{pattern.gsub('*', '.*')}/)
  end
  
  def flushdb
    @data.clear
  end
end

class LatvianPhoneCrawler
  attr_reader :redis, :websites, :timeout, :total_urls_processed, :total_numbers_extracted, :failed_urls
  
  def initialize(redis = nil)
    @redis = redis || MockRedis.new
    @websites = load_websites
    @timeout = 30
    @total_urls_processed = 0
    @total_numbers_extracted = 0
    @failed_urls = []
  end
  
  def load_websites
    [
      { "name" => "Test Site", "url" => "https://example.lv" },
      { "name" => "Test Site 2", "url" => "https://test.gov.lv" }
    ]
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
  
  def crawl_websites
    @websites.each_with_index do |website, index|
      url = website['url']
      name = website['name']
      
      begin
        phone_numbers = crawl_url(url)
        
        if phone_numbers.any?
          store_phone_numbers(phone_numbers, url)
          @total_numbers_extracted += phone_numbers.length
        end
        
        @total_urls_processed += 1
        
      rescue => e
        @failed_urls << { url: url, error: e.message }
        next
      end
    end
  end
end

class LatvianPhoneCrawlerIntegrationTest < Minitest::Test
  def setup
    @redis = MockRedis.new
  end
  
  def test_full_crawler_workflow_with_valid_data
    crawler = LatvianPhoneCrawler.new(@redis)
    
    # Mock HTML content with phone numbers
    html_with_phones = <<~HTML
      <html>
        <body>
          <h1>Contact Information</h1>
          <p>Phone: 22811907</p>
          <p>Alternative: +37167123456</p>
          <p>International: 00371 22 81 19 07</p>
          <p>With spaces: 22-81-19-07</p>
        </body>
      </html>
    HTML
    
    # Stub HTTP requests
    WebMock.stub_request(:get, "https://example.lv")
      .to_return(status: 200, body: html_with_phones)
    
    WebMock.stub_request(:get, "https://test.gov.lv")
      .to_return(status: 200, body: html_with_phones)
    
    # Run crawler
    crawler.crawl_websites
    
    # Verify results
    assert_equal 2, crawler.total_urls_processed
    assert_equal 4, crawler.total_numbers_extracted # Should be 4 unique numbers
    
    # Check Redis contains the phone numbers
    assert_equal 4, @redis.keys('371*').length
    assert @redis.sismember('37122811907', 'https://example.lv')
    assert @redis.sismember('37167123456', 'https://example.lv')
    assert @redis.sismember('37122811907', 'https://test.gov.lv')
  end
  
  def test_crawler_handles_failed_requests
    crawler = LatvianPhoneCrawler.new(@redis)
    
    # Stub successful and failed requests
    WebMock.stub_request(:get, "https://example.lv")
      .to_return(status: 200, body: "<html><body>Phone: 22811907</body></html>")
    
    WebMock.stub_request(:get, "https://test.gov.lv")
      .to_return(status: 500, body: "Internal Server Error")
    
    # Run crawler
    crawler.crawl_websites
    
    # Verify partial success
    assert_equal 1, crawler.total_urls_processed # Only one succeeded
    assert_equal 1, crawler.total_numbers_extracted
    assert_equal 1, crawler.failed_urls.length
    assert_equal "https://test.gov.lv", crawler.failed_urls.first[:url]
  end
  
  def test_crawler_handles_timeout
    crawler = LatvianPhoneCrawler.new(@redis)
    
    # Stub timeout
    WebMock.stub_request(:get, "https://example.lv")
      .to_timeout
    
    WebMock.stub_request(:get, "https://test.gov.lv")
      .to_return(status: 200, body: "<html><body>Phone: 67123456</body></html>")
    
    # Run crawler
    crawler.crawl_websites
    
    # Verify partial success
    assert_equal 1, crawler.total_urls_processed
    assert_equal 1, crawler.total_numbers_extracted
    assert_equal 1, crawler.failed_urls.length
  end
  
  def test_redis_set_prevents_duplicates
    crawler = LatvianPhoneCrawler.new(@redis)
    
    # HTML with the same number appearing multiple times
    html_with_duplicates = <<~HTML
      <html>
        <body>
          <p>Main: 22811907</p>
          <p>Alternative: 22-81-19-07</p>
          <p>Emergency: +37122811907</p>
        </body>
      </html>
    HTML
    
    WebMock.stub_request(:get, "https://example.lv")
      .to_return(status: 200, body: html_with_duplicates)
    
    # Run crawler
    crawler.crawl_websites
    
    # Should only store the number once per URL
    assert_equal 1, crawler.total_numbers_extracted
    assert_equal 1, @redis.scard('37122811907')
    assert @redis.sismember('37122811907', 'https://example.lv')
  end
end
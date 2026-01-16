require 'redis'
require 'json'

# Redis test data setup
module TestHelper
  class << self
    attr_reader :redis
    
    def setup_redis
      @redis ||= Redis.new(url: ENV['REDIS_URL'] || 'redis://localhost:6379')
      
      # Clear any existing test data
      clear_test_data
      
      # Populate with test data
      test_data = {
        '37122811907' => ['https://example.gov.lv', 'https://test.gov.lv'],
        '37166123456' => ['https://another.gov.lv'],
        '37167890123' => ['https://ministry.gov.lv', 'https://office.gov.lv', 'https://info.gov.lv'],
        '37129123456' => ['https://health.gov.lv'],
        '37123456789' => ['https://education.gov.lv']
      }
      
      test_data.each do |phone, urls|
        @redis.set(phone, JSON.generate(urls))
      end
      
      puts "✅ Redis test data populated with #{test_data.size} phone numbers"
    end
    
    def clear_test_data
      return unless @redis
      
      # Clear all keys that start with '371' (our test phone numbers)
      keys_to_clear = @redis.keys.select { |key| key.start_with?('371') }
      @redis.del(*keys_to_clear) unless keys_to_clear.empty?
      
      puts "🧹 Cleared #{keys_to_clear.size} test data keys from Redis"
    end
    
    def close_redis
      @redis.close if @redis
    end
    
    # Mock browser interaction for testing
    # In a real Playwright implementation, this would use actual browser automation
    def simulate_browser_interaction(&block)
      # Simulate browser context
      browser_data = {
        page_url: 'file:///home/engine/project/index.html',
        elements: {
          search_btn: '#searchBtn',
          phone_input: '#phoneInput',
          clear_btn: '#clearBtn',
          results: '#results',
          results_header: '#resultsHeader',
          error_message: '#errorMessage'
        }
      }
      
      # Simulate successful search for test data
      def browser_data.search_phone_number(phone_number)
        # Mock the search functionality that would happen in the browser
        normalized = normalize_phone(phone_number)
        redis = TestHelper.redis
        urls_json = redis.get(normalized)
        urls = urls_json ? JSON.parse(urls_json) : []
        
        {
          found: !urls.empty?,
          results: urls,
          normalized_number: normalized,
          header_text: urls.empty? ? "No results found for: #{phone_number}" : "Found #{urls.size} results:",
          results_count: urls.size,
          result_links: urls
        }
      rescue => e
        { error: e.message, found: false, results: [] }
      end
      
      def browser_data.normalize_phone(phone)
        phone.gsub(/\D/, '')
      end
      
      block.call(browser_data)
    end
    
    # Test URL patterns
    def get_test_urls
      {
        '37122811907' => ['https://example.gov.lv', 'https://test.gov.lv'],
        '37166123456' => ['https://another.gov.lv'],
        '37167890123' => ['https://ministry.gov.lv', 'https://office.gov.lv', 'https://info.gov.lv'],
        '37129123456' => ['https://health.gov.lv'],
        '37123456789' => ['https://education.gov.lv']
      }
    end
  end
end
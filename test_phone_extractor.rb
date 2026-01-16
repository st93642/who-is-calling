require 'minitest/autorun'
require 'json'

# Phone number extractor class to test
class PhoneExtractor
  # Extract and normalize Latvian phone numbers from HTML content
  def self.extract_and_normalize(html_content)
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
  
  private
  
  def self.normalize_to_latvian(number)
    # Remove all non-digit characters
    digits = number.gsub(/\D/, '')
    
    # Handle different formats
    if digits.start_with?('371')
      digits
    elsif digits.start_with?('371')
      digits
    elsif digits.length == 8 && digits[0] =~ /[2-9]/
      "371#{digits}"
    else
      digits
    end
  end
  
  def self.valid_latvian_number?(number)
    # Valid Latvian number: 371 + 8 digits
    number =~ /^371\d{8}$/
  end
end

class PhoneExtractorTest < Minitest::Test
  def setup
    @extractor = PhoneExtractor
  end
  
  def test_local_format_extraction
    html = "Contact us at 22811907"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_international_with_plus
    html = "Call us: +37122811907"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_international_with_00371
    html = "Dial 00371 22811907"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_with_spaces
    html = "Phone: 22 81 19 07"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_with_dashes
    html = "Contact: 22-81-19-07"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_with_parentheses
    html = "Call: (22) 81 19 07"
    result = @extractor.extract_and_normalize(html)
    assert_includes result, "37122811907"
  end
  
  def test_multiple_numbers
    html = "Main: 22811907, Secondary: 67123456"
    result = @extractor.extract_and_normalize(html)
    assert_equal 2, result.length
    assert_includes result, "37122811907"
    assert_includes result, "37167123456"
  end
  
  def test_no_duplicates_from_same_page
    html = "Call us at 22811907 or 22-81-19-07"
    result = @extractor.extract_and_normalize(html)
    assert_equal 1, result.length
    assert_includes result, "37122811907"
  end
  
  def test_invalid_numbers_skipped
    html = "Invalid: 1234567, 123456789, 07123456"
    result = @extractor.extract_and_normalize(html)
    assert_empty result
  end
  
  def test_empty_content
    assert_empty @extractor.extract_and_normalize("")
    assert_empty @extractor.extract_and_normalize(nil)
  end
end